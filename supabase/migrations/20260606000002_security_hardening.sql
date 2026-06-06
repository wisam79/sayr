-- Migration: 20260606000002_security_hardening.sql
-- Description: Comprehensive security hardening for all 12 business logic vulnerabilities
--            found in the security audit (Sayr v3).
-- Fixes applied:
--  1 & 6) Prevent drivers from changing route price / available_seats (trigger)
--  2) Reject zero-amount manual payment approvals + rate limit + audit amount
--  7) Prevent license reactivation (used to active, etc.)
--  8) Require pending status in update_payout_status (no back-flips)
--  10) Rating must be for a trip within subscription date range
--  12) Restrict profiles SELECT to own + admin only (drivers use profiles_public)

-- ============================================================================
-- FIX #1 & #6: Routes business columns protection (price / available_seats)
-- ============================================================================
-- A driver should NOT be able to arbitrarily change the route price or
-- refill consumed seats. Only admins may change these fields.

CREATE OR REPLACE FUNCTION public.routes_guard_business_columns()
RETURNS TRIGGER AS $$
BEGIN
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;

  IF NEW.price IS DISTINCT FROM OLD.price THEN
    RAISE EXCEPTION 'Only admins can change route price'
      USING ERRCODE = 'P0001';
  END IF;

  IF NEW.available_seats IS DISTINCT FROM OLD.available_seats THEN
    RAISE EXCEPTION 'Only admins can change available seats'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_routes_guard_business ON public.routes;
CREATE TRIGGER trigger_routes_guard_business
  BEFORE UPDATE ON public.routes
  FOR EACH ROW
  EXECUTE FUNCTION public.routes_guard_business_columns();

-- ============================================================================
-- FIX #2: admin_approve_payment - zero-amount check + rate limit + audit amount
-- ============================================================================
CREATE OR REPLACE FUNCTION public.admin_approve_payment(
  p_payment_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment RECORD;
  v_sub_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated'
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT * INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment record not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_payment.status != 'pending' THEN
    RAISE EXCEPTION 'Payment is already processed (status: %)', v_payment.status
      USING ERRCODE = 'P0001';
  END IF;

  -- REJECT zero or negative amount payments
  IF COALESCE(v_payment.amount, 0) <= 0 THEN
    RAISE EXCEPTION 'Cannot approve a payment with amount <= 0 (amount: %)', v_payment.amount
      USING ERRCODE = 'P0001';
  END IF;

  -- Rate limit: max 20 approvals per hour per admin
  -- check_rate_limit is already REVOKE FROM authenticated and granted to service_role,
  -- so calling from this SECURITY DEFINER context is safe.
  IF NOT public.check_rate_limit(auth.uid(), 'admin_approve_payment', 20, 3600) THEN
    RAISE EXCEPTION 'Too many payment approvals. Please try again later.'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.payments
  SET status = 'completed',
      paid_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payment_id;

  v_sub_id := public.complete_payment_and_activate_subscription(
    p_payment_id,
    v_payment.user_id,
    v_payment.license_id,
    v_payment.subscription_id
  );

  -- Audit log now includes the amount for transparency
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'payment_manually_approved',
    'payment',
    p_payment_id,
    jsonb_build_object(
      'subscription_id', v_payment.subscription_id,
      'license_id', v_payment.license_id,
      'student_id', v_payment.user_id,
      'amount', v_payment.amount,
      'currency', v_payment.currency
    )
  );

  RETURN v_sub_id;
END;
$$;

-- ============================================================================
-- FIX #7: License re-use prevention (trigger)
-- ============================================================================
-- Prevents reactivating a license after it has been used, expired, or revoked.
-- Also prevents clearing used_by on a used license.

CREATE OR REPLACE FUNCTION public.licenses_guard_reactivation()
RETURNS TRIGGER AS $$
BEGIN
  -- Any transition back to 'active' from used/expired/revoked is forbidden
  IF OLD.status IN ('used', 'expired', 'revoked') AND NEW.status = 'active' THEN
    RAISE EXCEPTION 'Cannot reactivate a license that was already (%, %, or revoked)',
      'used', 'expired'
      USING ERRCODE = 'P0001';
  END IF;

  -- Prevent clearing used_by on a used license
  IF OLD.status = 'used' AND OLD.used_by IS NOT NULL AND NEW.used_by IS NULL THEN
    RAISE EXCEPTION 'Cannot clear used_by on a used license'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS trigger_licenses_guard_reactivation ON public.licenses;
CREATE TRIGGER trigger_licenses_guard_reactivation
  BEFORE UPDATE ON public.licenses
  FOR EACH ROW
  EXECUTE FUNCTION public.licenses_guard_reactivation();

-- ============================================================================
-- FIX #8: update_payout_status - enforce status = 'pending' to prevent back-flip
-- ============================================================================
CREATE OR REPLACE FUNCTION public.update_payout_status(
  p_payout_id UUID,
  p_new_status TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_new_status NOT IN ('completed', 'rejected') THEN
    RAISE EXCEPTION 'Invalid status: %', p_new_status
      USING ERRCODE = 'P0001';
  END IF;

  -- Only allow updating from 'pending' status.
  UPDATE public.driver_payouts
  SET status = p_new_status,
      reference_note = COALESCE(p_note, reference_note),
      processed_by = auth.uid(),
      processed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payout_id
    AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payout not found or already processed'
      USING ERRCODE = 'P0001';
  END IF;
END;
$$;

-- ============================================================================
-- FIX #10: Ratings must be for a trip the student was actually subscribed to.
--          The trip's scheduled_at must fall within subscription window.
-- ============================================================================
DROP POLICY IF EXISTS "ratings_insert_own_student" ON public.ratings;

CREATE POLICY "ratings_insert_own_student"
  ON public.ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      JOIN public.trips t ON t.route_id = s.route_id
      WHERE s.student_id = auth.uid()
        AND t.id = trip_id
        AND t.driver_id = driver_id
        AND t.status = 'completed'
        AND t.scheduled_at BETWEEN s.start_date
        AND COALESCE(s.end_date, s.start_date + INTERVAL '30 days')
    )
  );

-- ============================================================================
-- FIX #12: Restrict profiles SELECT to own row + admin. Drivers must use
--          the profiles_public view (which excludes phone + fcm_token).
-- ============================================================================
-- The existing policy (post-20260604000001) allows any driver to read ALL
-- profiles including phone + fcm_token. We tighten that here.

DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;

CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    auth.uid() = id
    OR public.is_admin()
  );

-- Ensure the safe view is available for any code that needs it
GRANT SELECT ON public.profiles_public TO authenticated;
