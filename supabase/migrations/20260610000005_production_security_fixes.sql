-- Migration: 20260610000005_production_security_fixes.sql
-- Description: Production security fixes and hardening for boarding verification, rate limiting, and message immutability.

-- 1. Redefine validate_boarding_via_proximity to remove defaults on lat/lng and throw an exception if NULL
DROP FUNCTION IF EXISTS public.validate_boarding_via_proximity(UUID, TEXT, NUMERIC, NUMERIC);

CREATE OR REPLACE FUNCTION public.validate_boarding_via_proximity(
  p_trip_id UUID,
  p_otp TEXT,
  p_student_lat NUMERIC,
  p_student_lng NUMERIC
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


-- 2. Redefine check_rate_limit to use the bucketed timestamp calculation
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_limit INTEGER,
  p_window_seconds INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
BEGIN
  v_window_start := to_timestamp(floor(extract(epoch from NOW()) / p_window_seconds) * p_window_seconds);

  -- Get or create rate limit record
  INSERT INTO public.rate_limits (user_id, action, count, window_start, expires_at)
  VALUES (
    p_user_id,
    p_action,
    1,
    v_window_start,
    v_window_start + (p_window_seconds || ' seconds')::interval
  )
  ON CONFLICT (user_id, action, window_start)
  DO UPDATE SET count = rate_limits.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= p_limit;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INTEGER, INTEGER) TO service_role;


-- 3. Redefine enforce_message_immutability to include SET search_path = public
CREATE OR REPLACE FUNCTION public.enforce_message_immutability()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
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
$$;

DROP TRIGGER IF EXISTS trigger_enforce_message_immutability ON public.messages;
CREATE TRIGGER trigger_enforce_message_immutability
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_message_immutability();
