-- Migration: 20260611000001_payment_reconciliation.sql
-- Description: Direct Zain Cash payments decoupling from physical vouchers, seat reservation locks on pending, and Webhook-RPC compatibility.

-- 1. Modify create_payment RPC to:
--   - Make licenses optional for Zain Cash direct payments (default valid_days to 30)
--   - Deduct/reserve seat immediately on route when subscription is created in pending state
CREATE OR REPLACE FUNCTION public.create_payment(
  p_route_id UUID,
  p_amount NUMERIC,
  p_currency TEXT,
  p_method TEXT
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license_id UUID;
  v_valid_days INTEGER;
  v_subscription_id UUID;
  v_status TEXT;
  v_payment public.payments;
  v_route_price NUMERIC;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated'
      USING ERRCODE = 'P0001';
  END IF;

  -- Validate route and get its price
  SELECT price INTO v_route_price FROM public.routes WHERE id = p_route_id AND is_active = true;
  IF v_route_price IS NULL THEN
    RAISE EXCEPTION 'Route not found or inactive'
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify amount matches actual route price
  IF p_amount != v_route_price THEN
    RAISE EXCEPTION 'Incorrect payment amount. Expected %, Got %', v_route_price, p_amount
      USING ERRCODE = 'P0001';
  END IF;

  -- Check existing subscription
  SELECT id, license_id, status INTO v_subscription_id, v_license_id, v_status
  FROM public.subscriptions
  WHERE student_id = auth.uid()
    AND route_id = p_route_id
    AND status IN ('active', 'pending')
  LIMIT 1;

  IF FOUND THEN
    IF v_status = 'active' THEN
      RAISE EXCEPTION 'You already have an active subscription for this route'
        USING ERRCODE = 'P0001';
    END IF;
  ELSE
    -- Decouple licenses from direct payments
    IF p_method = 'zaincash' THEN
      v_license_id := NULL;
      v_valid_days := 30; -- Default duration for online payment subscriptions
    ELSE
      -- Find an active, unclaimed license (for cash/voucher flow)
      SELECT l.id, l.valid_days INTO v_license_id, v_valid_days
      FROM public.licenses l
      WHERE l.route_id = p_route_id
        AND l.status = 'active'
        AND l.used_by IS NULL
        AND NOT EXISTS (
          SELECT 1 FROM public.subscriptions s
          WHERE s.license_id = l.id
            AND s.status IN ('active', 'pending')
        )
      LIMIT 1
      FOR UPDATE SKIP LOCKED;

      IF v_license_id IS NULL THEN
        RAISE EXCEPTION 'No licenses available for this route'
          USING ERRCODE = 'P0001';
      END IF;
    END IF;

    -- Create pending subscription
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      p_route_id,
      v_license_id,
      'pending',
      NOW(),
      NOW() + (v_valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;

    -- Deduct seat immediately (Reserve seat)
    UPDATE public.routes
    SET available_seats = available_seats - 1,
        updated_at = NOW()
    WHERE id = p_route_id
      AND available_seats > 0;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'No seats available on route'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  -- Create pending payment
  INSERT INTO public.payments (
    user_id,
    subscription_id,
    license_id,
    amount,
    currency,
    method,
    status
  )
  VALUES (
    auth.uid(),
    v_subscription_id,
    v_license_id,
    p_amount,
    p_currency,
    p_method,
    'pending'
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;


-- 2. Modify complete_payment_and_activate_subscription RPC to:
--   - Allow both 'pending' and 'completed' statuses to make it compatible with process-payment Webhook
--   - Set status to 'completed' and paid_at inside the atomic call
--   - Make license locking/marking optional when license_id is NULL
--   - Do NOT deduct the seat here since it was already deducted/reserved on pending state
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
  v_payment_status TEXT;
  v_valid_days INTEGER := 30;
BEGIN
  -- Validate payment exists and is in pending or completed status
  SELECT status INTO v_payment_status
  FROM public.payments
  WHERE id = p_payment_id
    AND user_id = p_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment record not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_payment_status NOT IN ('pending', 'completed') THEN
    RAISE EXCEPTION 'Payment is not in a valid state for completion (status: %)', v_payment_status
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock license (only if license exists)
  IF p_license_id IS NOT NULL THEN
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
    
    v_valid_days := v_license.valid_days;
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

  -- STEP 1: Update subscription to active (seat is already deducted when pending)
  UPDATE public.subscriptions
  SET status = 'active',
      start_date = NOW(),
      end_date = NOW() + (v_valid_days || ' days')::interval,
      updated_at = NOW()
  WHERE id = p_subscription_id;

  -- STEP 2: Mark license as used (if applicable)
  IF p_license_id IS NOT NULL THEN
    UPDATE public.licenses
    SET status = 'used',
        used_by = p_user_id,
        used_at = NOW()
    WHERE id = p_license_id;
  END IF;

  -- STEP 3: Complete payment and link to subscription
  UPDATE public.payments
  SET status = 'completed',
      paid_at = COALESCE(paid_at, NOW()),
      subscription_id = p_subscription_id,
      updated_at = NOW()
  WHERE id = p_payment_id;

  -- STEP 4: Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    p_user_id,
    CASE WHEN p_license_id IS NOT NULL THEN 'license_activated' ELSE 'subscription_activated' END,
    CASE WHEN p_license_id IS NOT NULL THEN 'license' ELSE 'subscription' END,
    COALESCE(p_license_id, p_subscription_id),
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
    INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
    VALUES (
      p_user_id,
      'license_activation_failed',
      CASE WHEN p_license_id IS NOT NULL THEN 'license' ELSE 'subscription' END,
      COALESCE(p_license_id, p_subscription_id),
      jsonb_build_object(
        'error', SQLERRM,
        'subscription_id', p_subscription_id,
        'payment_id', p_payment_id
      )
    );
    RAISE;
END;
$$;


-- 3. Modify cancel_subscription RPC to return seats for active and pending subscriptions (including direct payments)
CREATE OR REPLACE FUNCTION public.cancel_subscription(
  p_subscription_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
BEGIN
  -- Lock the subscription
  SELECT * INTO v_sub
  FROM public.subscriptions
  WHERE id = p_subscription_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found'
      USING ERRCODE = 'P0001';
  END IF;

  -- Only the owner or admin can cancel
  IF v_sub.student_id != auth.uid() AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized'
      USING ERRCODE = 'P0001';
  END IF;

  -- Already cancelled?
  IF v_sub.status = 'cancelled' THEN
    RETURN;
  END IF;

  -- Update subscription
  UPDATE public.subscriptions
  SET status = 'cancelled',
      cancelled_at = NOW(),
      updated_at = NOW()
  WHERE id = p_subscription_id;

  -- Return seat to route (for active and pending subscriptions)
  IF v_sub.status IN ('active', 'pending') THEN
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;
  END IF;
END;
$$;


-- 4. Create reclaim_pending_reservations SQL function to:
--   - Release seats from pending subscriptions that have been pending for > 15 minutes
--   - Set associated pending payments to 'failed'
CREATE OR REPLACE FUNCTION public.reclaim_pending_reservations()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
BEGIN
  FOR v_sub IN
    UPDATE public.subscriptions
    SET status = 'cancelled',
        cancel_reason = 'Payment timeout (15 minutes)',
        updated_at = NOW()
    WHERE status = 'pending'
      AND created_at <= NOW() - INTERVAL '15 minutes'
    RETURNING id, route_id
  LOOP
    -- Return seat to route
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;

    -- Mark associated pending payments as failed
    UPDATE public.payments
    SET status = 'failed',
        metadata = metadata || '{"failure_reason": "Payment timeout (15 minutes)"}'::jsonb,
        updated_at = NOW()
    WHERE subscription_id = v_sub.id
      AND status = 'pending';
  END LOOP;
END;
$$;

-- Schedule pg_cron job to run reclaim_pending_reservations() every 5 minutes
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'reclaim_pending_reservations_job';
SELECT cron.schedule('reclaim_pending_reservations_job', '*/5 * * * *', 'SELECT public.reclaim_pending_reservations();');
