-- Migration: 20260610000001_fix_license_activation.sql
-- Description: Fix activate_license RPC to active immediately, mark license used, deduct seat, and fix pending subscriptions.

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

  -- STEP 1: Create subscription (active immediately)
  BEGIN
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      v_license.route_id,
      v_license.id,
      'active',
      NOW(),
      NOW() + (v_license.valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Duplicate subscription detected'
        USING ERRCODE = 'P0001';
  END;

  -- STEP 2: Deduct seat from route
  UPDATE public.routes
  SET available_seats = available_seats - 1,
      updated_at = NOW()
  WHERE id = v_license.route_id
    AND available_seats > 0;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No seats available on route'
      USING ERRCODE = 'P0001';
  END IF;

  -- STEP 3: Mark license as used
  UPDATE public.licenses
  SET status = 'used',
      used_by = auth.uid(),
      used_at = NOW()
  WHERE id = v_license.id;

  -- STEP 4: Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'license_activated',
    'license',
    v_license.id,
    jsonb_build_object(
      'subscription_id', v_subscription_id,
      'route_id', v_license.route_id
    )
  );

  RETURN v_subscription_id;
END;
$$;

-- Revoke execute from public and anon, grant to authenticated
REVOKE EXECUTE ON FUNCTION public.activate_license(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.activate_license(TEXT) TO authenticated;

-- Fix any existing pending subscriptions from licenses
DO $$
DECLARE
  v_sub RECORD;
BEGIN
  FOR v_sub IN
    SELECT s.id, s.student_id, s.route_id, s.license_id
    FROM public.subscriptions s
    WHERE s.status = 'pending' AND s.license_id IS NOT NULL
  LOOP
    -- Mark subscription active
    UPDATE public.subscriptions
    SET status = 'active',
        updated_at = NOW()
    WHERE id = v_sub.id;

    -- Deduct seat
    UPDATE public.routes
    SET available_seats = GREATEST(0, available_seats - 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;

    -- Mark license as used
    UPDATE public.licenses
    SET status = 'used',
        used_by = v_sub.student_id,
        used_at = NOW()
    WHERE id = v_sub.license_id;
  END LOOP;
END;
$$;
