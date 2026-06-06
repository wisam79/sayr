-- Migration: 20260606000003_fix_vulnerabilities.sql
-- Description: Fix security vulnerabilities and logical issues (Sayr v3):
--   1) Atomic payment and subscription activation.
--   2) Automatic seat reclamation on subscription expiration (pg_cron).
--   3) Prevention of message read receipt forgery by the sender.
--   4) Silent SOS injection prevention (drop direct INSERT policy on emergency_reports).

-- ============================================================================
-- FIX #1: Atomic payment and subscription activation
-- ============================================================================

CREATE OR REPLACE FUNCTION public.complete_payment_and_activate_subscription(
  p_payment_id UUID,
  p_user_id UUID,
  p_license_id UUID,
  p_subscription_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license RECORD;
  v_subscription RECORD;
  v_route_id UUID;
BEGIN
  -- Validate payment exists and is in pending status (moved from edge function)
  PERFORM 1 FROM public.payments
    WHERE id = p_payment_id
      AND user_id = p_user_id
      AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found or not pending'
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock license
  SELECT id, route_id, status, used_by, valid_days
  INTO v_license
  FROM public.licenses
  WHERE id = p_license_id
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'License not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.status != 'active' THEN
    RAISE EXCEPTION 'License is not active (status: %)', v_license.status
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.used_by IS NOT NULL THEN
    RAISE EXCEPTION 'License already used'
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock subscription
  SELECT id, route_id, status
  INTO v_subscription
  FROM public.subscriptions
  WHERE id = p_subscription_id
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found'
      USING ERRCODE = 'P0001';
  END IF;

  v_route_id := v_subscription.route_id;

  -- STEP 1: Update subscription to active (BEFORE seat deduction)
  UPDATE public.subscriptions
  SET status = 'active',
      start_date = NOW(),
      end_date = NOW() + (v_license.valid_days || ' days')::interval,
      updated_at = NOW()
  WHERE id = p_subscription_id;

  -- STEP 2: Deduct seat (only after subscription is active)
  UPDATE public.routes
  SET available_seats = available_seats - 1,
      updated_at = NOW()
  WHERE id = v_route_id
    AND available_seats > 0;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No seats available on route'
      USING ERRCODE = 'P0001';
  END IF;

  -- STEP 3: Mark license as used
  UPDATE public.licenses
  SET status = 'used',
      used_by = p_user_id,
      used_at = NOW()
  WHERE id = p_license_id;

  -- STEP 4: Update payment status to completed and link
  UPDATE public.payments
  SET subscription_id = p_subscription_id,
      status = 'completed',
      paid_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payment_id;

  -- STEP 5: Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    p_user_id,
    'license_activated',
    'license',
    p_license_id,
    jsonb_build_object(
      'subscription_id', p_subscription_id,
      'payment_id', p_payment_id,
      'route_id', v_route_id
    )
  );

  RETURN p_subscription_id;
EXCEPTION
  WHEN OTHERS THEN
    -- The whole transaction rolls back automatically.
    RAISE;
END;
$$;

-- Redefine admin_approve_payment to call complete_payment_and_activate_subscription atomically
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
  IF NOT public.check_rate_limit(auth.uid(), 'admin_approve_payment', 20, 3600) THEN
    RAISE EXCEPTION 'Too many payment approvals. Please try again later.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Call the atomic function
  v_sub_id := public.complete_payment_and_activate_subscription(
    p_payment_id,
    v_payment.user_id,
    v_payment.license_id,
    v_payment.subscription_id
  );

  -- Audit log manual approval
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
-- FIX #2: Automatic seat reclamation on subscription expiration
-- ============================================================================

CREATE OR REPLACE FUNCTION public.expire_subscriptions_and_return_seats()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
BEGIN
  -- Lock and update active subscriptions that are past their end_date
  FOR v_sub IN
    UPDATE public.subscriptions
    SET status = 'expired',
        updated_at = NOW()
    WHERE status = 'active'
      AND end_date <= NOW()
    RETURNING route_id, license_id
  LOOP
    -- Return seat to route
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;

    -- Mark license as expired
    IF v_sub.license_id IS NOT NULL THEN
      UPDATE public.licenses
      SET status = 'expired'
      WHERE id = v_sub.license_id;
    END IF;
  END LOOP;
END;
$$;

-- Schedule pg_cron job to run every hour (unschedule first if exists)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'expire_subscriptions_job';
SELECT cron.schedule('expire_subscriptions_job', '0 * * * *', 'SELECT public.expire_subscriptions_and_return_seats();');

-- ============================================================================
-- FIX #3: Prevent message read receipt forgery by the sender
-- ============================================================================

CREATE OR REPLACE FUNCTION public.enforce_message_immutability()
RETURNS TRIGGER AS $$
BEGIN
  -- If the caller is the sender of the message, they are not allowed to modify read receipts (is_read / read_at)
  IF OLD.sender_id = auth.uid() AND (NEW.is_read IS DISTINCT FROM OLD.is_read OR NEW.read_at IS DISTINCT FROM OLD.read_at) THEN
    RAISE EXCEPTION 'Sender cannot modify read receipts' USING ERRCODE = 'P0001';
  END IF;

  -- Verify other immutable columns
  IF NEW.body IS DISTINCT FROM OLD.body THEN
    RAISE EXCEPTION 'Cannot modify message body' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.sender_id IS DISTINCT FROM OLD.sender_id THEN
    RAISE EXCEPTION 'Cannot modify message sender' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.conversation_id IS DISTINCT FROM OLD.conversation_id THEN
    RAISE EXCEPTION 'Cannot modify message conversation' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'Cannot modify message creation time' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FIX #4: Drop direct INSERT policy on emergency_reports (prevent silent SOS injection)
-- ============================================================================

DROP POLICY IF EXISTS "emergency_insert_own" ON public.emergency_reports;
