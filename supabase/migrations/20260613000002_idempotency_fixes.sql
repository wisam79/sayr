-- Migration: 20260613000002_idempotency_fixes.sql
-- Description: Add idempotency_key to payments table, update create_payment to enforce idempotency,
--              and update activate_license to return existing active subscription if already activated by caller.

-- 1. Add idempotency_key column to payments table
ALTER TABLE public.payments ADD COLUMN IF NOT EXISTS idempotency_key TEXT UNIQUE;

-- 2. Drop old create_payment function signature
DROP FUNCTION IF EXISTS public.create_payment(UUID, NUMERIC, TEXT, TEXT);

-- 3. Declare new create_payment function with p_idempotency_key
CREATE OR REPLACE FUNCTION public.create_payment(
  p_route_id UUID,
  p_amount NUMERIC,
  p_currency TEXT,
  p_method TEXT,
  p_idempotency_key TEXT DEFAULT NULL
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

  -- Idempotency check
  IF p_idempotency_key IS NOT NULL THEN
    SELECT * INTO v_payment
    FROM public.payments
    WHERE idempotency_key = p_idempotency_key;
    
    IF FOUND THEN
      RETURN v_payment;
    END IF;
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
    status,
    idempotency_key
  )
  VALUES (
    auth.uid(),
    v_subscription_id,
    v_license_id,
    p_amount,
    p_currency,
    p_method,
    'pending',
    p_idempotency_key
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;

-- Revoke execute from public and anon, grant to authenticated
REVOKE EXECUTE ON FUNCTION public.create_payment(UUID, NUMERIC, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_payment(UUID, NUMERIC, TEXT, TEXT, TEXT) TO authenticated;

-- 4. Re-declare activate_license to support self-healing idempotency
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

  -- Idempotency check: If license is already used by the same user, return their active subscription
  IF v_license.status = 'used' AND v_license.used_by = auth.uid() THEN
    SELECT id INTO v_subscription_id
    FROM public.subscriptions
    WHERE license_id = v_license.id
      AND student_id = auth.uid()
      AND status = 'active';
    
    IF FOUND THEN
      RETURN v_subscription_id;
    END IF;
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
