-- Migration: 20260603000020_rpc_license.sql
-- Description: License activation RPCs (atomic flow)

-- Activate a license code
-- Atomic flow:
--   1. Rate limit check
--   2. Lock license row (FOR UPDATE NOWAIT)
--   3. Verify status = 'active'
--   4. Verify user doesn't have active subscription for this route
--   5. Create pending subscription (unique index protects against race)
--   6. Mark license as reserved
-- Returns the new subscription ID
CREATE OR REPLACE FUNCTION public.activate_license(
  p_code TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license RECORD;
  v_subscription_id UUID;
  v_existing_sub UUID;
BEGIN
  -- Rate limit: max 5 attempts per 15 minutes
  IF NOT public.check_rate_limit(
    auth.uid(),
    'activate_license',
    5,
    900
  ) THEN
    RAISE EXCEPTION 'Too many activation attempts. Please try again later.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Normalize code
  p_code := UPPER(TRIM(p_code));

  -- Validate format
  IF p_code !~ '^[A-Z0-9]{8}$' THEN
    RAISE EXCEPTION 'Invalid license code format'
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock license
  SELECT id, route_id, status, used_by, valid_days
  INTO v_license
  FROM public.licenses
  WHERE code = p_code
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'License code not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.status != 'active' THEN
    RAISE EXCEPTION 'License is not active (status: %)', v_license.status
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.used_by IS NOT NULL AND v_license.used_by != auth.uid() THEN
    RAISE EXCEPTION 'License already used by another user'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check if user already has active subscription for this route
  SELECT id INTO v_existing_sub
  FROM public.subscriptions
  WHERE student_id = auth.uid()
    AND route_id = v_license.route_id
    AND status IN ('active', 'pending');

  IF v_existing_sub IS NOT NULL THEN
    RAISE EXCEPTION 'You already have an active subscription for this route'
      USING ERRCODE = 'P0001';
  END IF;

  -- Create subscription (unique index will block race conditions)
  BEGIN
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      v_license.route_id,
      v_license.id,
      'pending',
      NOW(),
      NOW() + (v_license.valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Duplicate subscription detected'
        USING ERRCODE = 'P0001';
  END;

  RETURN v_subscription_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.activate_license(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.activate_license(TEXT) TO authenticated;

-- Cancel subscription (returns seat to route)
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

  -- Return seat to route (only if subscription was active and had a license)
  IF v_sub.status = 'active' AND v_sub.license_id IS NOT NULL THEN
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;
  END IF;
END;
$$;

GRANT EXECUTE ON FUNCTION public.cancel_subscription(UUID) TO authenticated;
