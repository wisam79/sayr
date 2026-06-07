-- Migration: 20260607000003_postgis_geo_verification.sql
-- Description: Enable postgis extension and replace simple bounding-box checks with exact ST_DistanceSphere calculations

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- ----------------------------------------------------------------------------
-- RPC: validate_boarding
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_boarding(
  p_token TEXT,
  p_trip_id UUID,
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL
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
  v_token_record RECORD;
  v_token_hash TEXT;
  v_boarding_id UUID;
  v_student_name TEXT;
  v_geo_ok BOOLEAN := true;
BEGIN
  IF v_user_id IS NULL THEN
    RAISE EXCEPTION 'Not authenticated' USING ERRCODE = 'P0001';
  END IF;

  -- Rate limit: max 30 scans/min per driver.
  IF NOT public.check_rate_limit(v_user_id, 'validate_boarding', 30, 60) THEN
    RAISE EXCEPTION 'Too many scan attempts, slow down'
      USING ERRCODE = 'P0001';
  END IF;

  -- Look up the trip and lock it.
  SELECT t.id, t.driver_id, t.status, t.scheduled_at, t.last_lat, t.last_lng
  INTO v_trip
  FROM public.trips t
  WHERE t.id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trip not found' USING ERRCODE = 'P0001';
  END IF;

  -- Caller must be the assigned driver.
  IF v_trip.driver_id NOT IN (
    SELECT id FROM public.drivers WHERE user_id = v_user_id
  ) THEN
    RAISE EXCEPTION 'Not authorized for this trip' USING ERRCODE = 'P0001';
  END IF;

  IF v_trip.status NOT IN ('driver_waiting', 'in_transit') THEN
    RAISE EXCEPTION 'Trip is not accepting boardings' USING ERRCODE = 'P0001';
  END IF;

  -- Hash the provided token.
  v_token_hash := encode(digest(p_token, 'sha256'), 'hex');

  -- Look up the token (and lock it).
  SELECT bt.id, bt.subscription_id, bt.trip_id, bt.student_id,
         bt.expires_at, bt.consumed_at
  INTO v_token_record
  FROM public.boarding_tokens bt
  WHERE bt.token_hash = v_token_hash
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invalid token' USING ERRCODE = 'P0001';
  END IF;

  IF v_token_record.consumed_at IS NOT NULL THEN
    RAISE EXCEPTION 'Token already used' USING ERRCODE = 'P0001';
  END IF;

  IF v_token_record.expires_at < NOW() THEN
    RAISE EXCEPTION 'Token has expired' USING ERRCODE = 'P0001';
  END IF;

  IF v_token_record.trip_id != p_trip_id THEN
    RAISE EXCEPTION 'Token is for a different trip' USING ERRCODE = 'P0001';
  END IF;

  -- Optional geo verification: if driver provided location, ensure they're
  -- within 500m of the trip's last known location.
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL
     AND v_trip.last_lat IS NOT NULL AND v_trip.last_lng IS NOT NULL THEN
    v_geo_ok := extensions.ST_DistanceSphere(
      extensions.ST_MakePoint(p_lng, p_lat),
      extensions.ST_MakePoint(v_trip.last_lng, v_trip.last_lat)
    ) <= 500.0;
    IF NOT v_geo_ok THEN
      RAISE EXCEPTION 'Driver location does not match trip location'
        USING ERRCODE = 'P0001';
    END IF;
  END IF;

  -- Look up the student name for the response.
  SELECT full_name INTO v_student_name
  FROM public.profiles
  WHERE id = v_token_record.student_id;

  -- Mark the token as consumed.
  UPDATE public.boarding_tokens
  SET consumed_at = NOW(),
      consumed_by_trip_id = p_trip_id
  WHERE id = v_token_record.id;

  -- Create the boarding record. Unique constraint blocks duplicates.
  BEGIN
    INSERT INTO public.boardings (
      trip_id, subscription_id, student_id, boarded_lat, boarded_lng
    )
    VALUES (
      p_trip_id, v_token_record.subscription_id, v_token_record.student_id,
      p_lat, p_lng
    )
    RETURNING id INTO v_boarding_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Student already boarded this trip'
        USING ERRCODE = 'P0001';
  END;

  -- Audit log.
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    v_user_id,
    'student_boarded',
    'trip',
    p_trip_id,
    jsonb_build_object(
      'boarding_id', v_boarding_id,
      'student_id', v_token_record.student_id,
      'lat', p_lat,
      'lng', p_lng
    )
  );

  RETURN QUERY
  SELECT v_boarding_id,
         v_token_record.student_id,
         v_student_name,
         v_token_record.subscription_id,
         NOW();
END;
$$;

REVOKE EXECUTE ON FUNCTION public.validate_boarding(TEXT, UUID, NUMERIC, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_boarding(TEXT, UUID, NUMERIC, NUMERIC) TO authenticated;


-- ----------------------------------------------------------------------------
-- RPC: validate_boarding_via_proximity
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.validate_boarding_via_proximity(
  p_trip_id UUID,
  p_otp TEXT,
  p_student_lat NUMERIC DEFAULT NULL,
  p_student_lng NUMERIC DEFAULT NULL
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

  -- Verify BLE OTP
  IF v_trip.ble_otp IS NULL OR v_trip.ble_otp != p_otp THEN
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

  -- Optional geo verification: ensure student is within 50m of driver
  IF p_student_lat IS NOT NULL AND p_student_lng IS NOT NULL
     AND v_trip.last_lat IS NOT NULL AND v_trip.last_lng IS NOT NULL THEN
    v_geo_ok := extensions.ST_DistanceSphere(
      extensions.ST_MakePoint(p_student_lng, p_student_lat),
      extensions.ST_MakePoint(v_trip.last_lng, v_trip.last_lat)
    ) <= 50.0;
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

REVOKE EXECUTE ON FUNCTION public.validate_boarding_via_proximity(UUID, TEXT, NUMERIC, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.validate_boarding_via_proximity(UUID, TEXT, NUMERIC, NUMERIC) TO authenticated;
