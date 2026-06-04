-- Migration: 20260603000010_payments.sql
-- Description: Payment records (Zain Cash + cash)
-- CRITICAL: Contains the P0 race condition fix

CREATE TABLE public.payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subscription_id UUID REFERENCES public.subscriptions(id) ON DELETE SET NULL,
  license_id UUID REFERENCES public.licenses(id) ON DELETE SET NULL,
  amount NUMERIC(10, 2) NOT NULL CHECK (amount >= 0),
  currency TEXT NOT NULL DEFAULT 'IQD',
  method TEXT NOT NULL CHECK (method IN ('zaincash', 'cash', 'manual')),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'failed', 'refunded')),
  reference_id TEXT,
  reference_url TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_user ON public.payments(user_id);
CREATE INDEX idx_payments_subscription ON public.payments(subscription_id);
CREATE INDEX idx_payments_status ON public.payments(status);
CREATE INDEX idx_payments_reference ON public.payments(reference_id);

ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;

-- Users can read their own payments
CREATE POLICY "payments_select_own"
  ON public.payments FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Drivers can read payments for their routes (via subscriptions)
CREATE POLICY "payments_select_driver"
  ON public.payments FOR SELECT
  TO authenticated
  USING (
    subscription_id IN (
      SELECT s.id FROM public.subscriptions s
      JOIN public.routes r ON s.route_id = r.id
      JOIN public.drivers d ON r.driver_id = d.id
      WHERE d.user_id = auth.uid()
    )
  );

-- Admins can manage all
CREATE POLICY "payments_all_admin"
  ON public.payments FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Service role can insert (for Edge Functions / webhooks)
CREATE POLICY "payments_insert_service"
  ON public.payments FOR INSERT
  TO service_role
  WITH CHECK (true);

CREATE TRIGGER set_payments_updated_at
  BEFORE UPDATE ON public.payments
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- P0 FIX: complete_payment_and_activate_subscription
-- ============================================================================
-- The original function had this race condition:
--   1. Seat is deducted before subscription is created
--   2. If INSERT fails, seat is lost and user paid without service
--
-- Fix: Use a single transaction with proper ordering:
--   1. Lock license row (FOR UPDATE NOWAIT)
--   2. Insert payment record (so we have a record even if subscription fails)
--   3. Create subscription FIRST (if this fails, rollback payment + seat)
--   4. Only AFTER subscription is created, deduct the seat
--   5. Mark license as used
-- All in one transaction with explicit exception handling.
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
  -- Validate payment exists and is in pending status
  -- (completed by the webhook before calling this)
  PERFORM 1 FROM public.payments
    WHERE id = p_payment_id
      AND user_id = p_user_id
      AND status = 'completed';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment not found or not completed'
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

  -- STEP 4: Link payment to subscription
  UPDATE public.payments
  SET subscription_id = p_subscription_id,
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
    -- But we add an audit log for debugging.
    INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
    VALUES (
      p_user_id,
      'license_activation_failed',
      'license',
      p_license_id,
      jsonb_build_object(
        'error', SQLERRM,
        'subscription_id', p_subscription_id,
        'payment_id', p_payment_id
      )
    );
    RAISE;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.complete_payment_and_activate_subscription(
  UUID, UUID, UUID, UUID
) FROM PUBLIC, anon;

GRANT EXECUTE ON FUNCTION public.complete_payment_and_activate_subscription(
  UUID, UUID, UUID, UUID
) TO service_role;
