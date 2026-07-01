-- Migration: 20260630000001_fix_audited_logic_vulnerabilities.sql
-- Description: Fix critical business logic vulnerabilities discovered during security audit.
--   1. Geofence Bypass via Null Coordinates Regression.
--   2. Seat Capacity Bypass via Subscription Cancellation Race Condition.
--   3. OTP Authentication Bypass via SQL Null Semantics.

-- ============================================================================
-- FIX #1 & #3: Proximity Boarding Geofence & OTP Bypass
-- ============================================================================

CREATE OR REPLACE FUNCTION public.validate_boarding_via_proximity(
  p_trip_id UUID,
  p_otp TEXT,
  p_student_lat NUMERIC DEFAULT NULL, -- Reverted to avoid SQLSTATE 42P13, checked in body
  p_student_lng NUMERIC DEFAULT NULL  -- Reverted to avoid SQLSTATE 42P13, checked in body
)
RETURNS TABLE (
  boarding_id UUID,
  student_id UUID,
  student_name TEXT,
  subscription_id UUID,
  boarded_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_id UUID := auth.uid();
  v_trip RECORD;
  v_subscription RECORD;
  v_boarding_id UUID;
  v_student_name TEXT;
  v_geo_ok BOOLEAN := true;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'P0001';
  END IF;

  -- 1) FIX FOR VULNERABILITY 3 (OTP Null Semantics)
  -- Explicitly reject NULL OTP values.
  IF p_otp IS NULL THEN
    RAISE EXCEPTION 'OTP is required' USING ERRCODE = 'P0001';
  END IF;

  -- 2) FIX FOR VULNERABILITY 1 (Geofence Bypass)
  -- Explicitly reject NULL location values.
  IF p_student_lat IS NULL OR p_student_lng IS NULL THEN
    RAISE EXCEPTION 'Student location is required for proximity boarding' USING ERRCODE = 'P0001';
  END IF;

  -- Rate limit: max 10 check-ins per minute per student.
  IF NOT public.check_rate_limit(v_user_id, 'validate_boarding_via_proximity', 10, 60) THEN
    RAISE EXCEPTION 'Too many attempts, slow down'
      USING ERRCODE = 'P0001';
  END IF;

  -- Look up the trip and lock it.
  SELECT t.id, t.driver_id, t.status, t.last_lat, t.last_lng, t.ble_otp, t.ble_otp_expires_at, t.route_id
  INTO v_trip
  FROM public.trips t
  WHERE t.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trip not found' USING ERRCODE = 'P0001';
  END IF;

  IF v_trip.status NOT IN ('driver_waiting', 'in_transit') THEN
    RAISE EXCEPTION 'Trip is not accepting boardings' USING ERRCODE = 'P0001';
  END IF;

  -- Verify BLE OTP securely using IS DISTINCT FROM
  IF v_trip.ble_otp IS DISTINCT FROM p_otp THEN
    RAISE EXCEPTION 'Invalid proximity OTP' USING ERRCODE = 'P0001';
  END IF;

  IF v_trip.ble_otp_expires_at < NOW() THEN
    RAISE EXCEPTION 'Proximity OTP has expired' USING ERRCODE = 'P0001';
  END IF;

  -- Look up student's active subscription for this route
  SELECT s.id, s.student_id, s.route_id, s.status, s.end_date, s.license_id
  INTO v_subscription
  FROM public.subscriptions s
  WHERE s.student_id = v_user_id
    AND s.route_id = v_trip.route_id
    AND s.status = 'active'
    AND (s.end_date IS NULL OR s.end_date > NOW())
  ORDER BY s.start_date DESC
  LIMIT 1;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No active subscription found for this route'
      USING ERRCODE = 'P0001';
  END IF;

  -- Geo verification: ensure student is within 30m of driver.
  IF v_trip.last_lat IS NOT NULL AND v_trip.last_lng IS NOT NULL THEN
    v_geo_ok := extensions.ST_DistanceSphere(
      extensions.ST_MakePoint(p_student_lng, p_student_lat),
      extensions.ST_MakePoint(v_trip.last_lng, v_trip.last_lat)
    ) <= 30.0;
    IF NOT v_geo_ok THEN
      RAISE EXCEPTION 'Your location is too far from the bus'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  -- Look up student name.
  SELECT full_name INTO v_student_name
  FROM public.profiles
  WHERE id = v_user_id;

  -- Create the boarding record. Unique constraint blocks duplicates.
  BEGIN
    INSERT INTO public.boardings (
      trip_id, subscription_id, student_id, boarded_lat, boarded_lng, boarding_method
    )
    VALUES (
      p_trip_id, v_subscription.id, v_user_id, p_student_lat, p_student_lng, 'self_check_in'
    )
    RETURNING id INTO v_boarding_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'You have already boarded this trip'
        USING ERRCODE = 'P0001';
  END;

  -- Audit log.
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    v_user_id,
    'student_boarded_proximity',
    'trip',
    p_trip_id,
    jsonb_build_object(
      'boarding_id', v_boarding_id,
      'lat', p_student_lat,
      'lng', p_student_lng,
      'method', 'self_check_in'
    )
  );

  RETURN QUERY
  SELECT v_boarding_id,
         v_user_id,
         v_student_name,
         v_subscription.id,
         NOW();
END;
$$;


-- ============================================================================
-- FIX #2: Seat Capacity Bypass via Subscription Cancellation
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

  -- FIX FOR VULNERABILITY 2 (Seat Capacity Bypass)
  -- Ensure that the subscription hasn't been cancelled prematurely.
  IF v_subscription.status != 'pending' THEN
    RAISE EXCEPTION 'Cannot activate a subscription that is not pending (Current status: %)', v_subscription.status
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
