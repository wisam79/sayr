-- Migration: 20260618000001_report_security_fixes.sql
-- Description: Implement security fixes from the Sayr Technical Review Report
--   Fix #1: Restrict trips SELECT policy to authenticated users who are part of the trip.
--   Fix #3: Protect driver license PII by converting drivers to a VIEW and renaming base table.
--   Fix #4: Allow students to resolve their own emergency reports, with strict column modification restrictions.
--   Fix #5: Validate student subscription status in conversations INSERT policy.
--   Fix #6: Tighter geofencing checks for validate_boarding (100m) and validate_boarding_via_proximity (30m).
--   Fix #7: Create secure admin_resolve_emergency RPC to restrict admin emergency updates.

-- ============================================================
-- Fix #3: Rename public.drivers to public.drivers_data and create VIEW
-- ============================================================
ALTER TABLE public.drivers RENAME TO drivers_data;

CREATE OR REPLACE VIEW public.drivers AS
SELECT 
  id,
  user_id,
  vehicle_model,
  vehicle_plate,
  capacity,
  is_verified,
  rating,
  total_trips,
  created_at,
  updated_at,
  -- Only expose license_number to the driver themselves or admin
  CASE 
    WHEN user_id = auth.uid() OR public.is_admin() THEN license_number
    ELSE NULL
  END AS license_number,
  -- Only expose license_expiry to the driver themselves or admin
  CASE 
    WHEN user_id = auth.uid() OR public.is_admin() THEN license_expiry
    ELSE NULL
  END AS license_expiry
FROM public.drivers_data;

GRANT SELECT, INSERT, UPDATE, DELETE ON public.drivers TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.drivers TO service_role;

CREATE OR REPLACE FUNCTION public.manage_drivers_view()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO public.drivers_data (
      id, user_id, vehicle_model, vehicle_plate, capacity, license_number, license_expiry, is_verified, rating, total_trips, created_at, updated_at
    ) VALUES (
      COALESCE(NEW.id, gen_random_uuid()), NEW.user_id, NEW.vehicle_model, NEW.vehicle_plate, NEW.capacity, NEW.license_number, NEW.license_expiry, COALESCE(NEW.is_verified, false), COALESCE(NEW.rating, 0), COALESCE(NEW.total_trips, 0), COALESCE(NEW.created_at, NOW()), COALESCE(NEW.updated_at, NOW())
    ) RETURNING * INTO NEW;
    RETURN NEW;
  ELSIF TG_OP = 'UPDATE' THEN
    UPDATE public.drivers_data SET
      vehicle_model = NEW.vehicle_model,
      vehicle_plate = NEW.vehicle_plate,
      capacity = NEW.capacity,
      license_number = CASE WHEN OLD.user_id = auth.uid() OR public.is_admin() THEN NEW.license_number ELSE license_number END,
      license_expiry = CASE WHEN OLD.user_id = auth.uid() OR public.is_admin() THEN NEW.license_expiry ELSE license_expiry END,
      is_verified = NEW.is_verified,
      rating = NEW.rating,
      total_trips = NEW.total_trips,
      updated_at = NOW()
    WHERE id = OLD.id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    DELETE FROM public.drivers_data WHERE id = OLD.id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_manage_drivers_view
  INSTEAD OF INSERT OR UPDATE OR DELETE ON public.drivers
  FOR EACH ROW
  EXECUTE FUNCTION public.manage_drivers_view();


-- ============================================================
-- Fix #1: Restrict trips SELECT policy
-- ============================================================
DROP POLICY IF EXISTS "trips_select_authenticated" ON public.trips;

CREATE POLICY "trips_select_authenticated"
  ON public.trips FOR SELECT
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers_data WHERE user_id = auth.uid())
    OR route_id IN (
      SELECT route_id FROM public.subscriptions
      WHERE student_id = auth.uid() AND status = 'active'
    )
    OR public.is_admin()
  );


-- ============================================================
-- Fix #4: Allow students to resolve emergency reports with trigger validation
-- ============================================================
CREATE POLICY "emergency_update_own"
  ON public.emergency_reports FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

CREATE OR REPLACE FUNCTION public.enforce_emergency_report_update_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT public.is_admin() THEN
    -- Student can only transition to 'resolved' and cannot undo resolution
    IF NEW.status != 'resolved' OR OLD.status = 'resolved' THEN
      RAISE EXCEPTION 'Students can only transition status to resolved' USING ERRCODE = 'P0001';
    END IF;
    IF NEW.resolved_at IS NULL THEN
      RAISE EXCEPTION 'resolved_at must be provided when resolving' USING ERRCODE = 'P0001';
    END IF;
    -- Rest of the columns must remain unchanged
    IF NEW.user_id != OLD.user_id OR
       NEW.trip_id != OLD.trip_id OR
       NEW.latitude != OLD.latitude OR
       NEW.longitude != OLD.longitude OR
       NEW.message IS DISTINCT FROM OLD.message OR
       NEW.resolved_by IS DISTINCT FROM OLD.resolved_by OR
       NEW.notes IS DISTINCT FROM OLD.notes OR
       NEW.created_at != OLD.created_at THEN
      RAISE EXCEPTION 'Cannot modify read-only fields on emergency report' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_enforce_emergency_report_update_rules ON public.emergency_reports;
CREATE TRIGGER trigger_enforce_emergency_report_update_rules
  BEFORE UPDATE ON public.emergency_reports
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_emergency_report_update_rules();


-- ============================================================
-- Fix #5: Conversations insert policy subscription check
-- ============================================================
DROP POLICY IF EXISTS "conversations_insert_participants" ON public.conversations;

CREATE POLICY "conversations_insert_participants"
  ON public.conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    (student_id = auth.uid() OR driver_user_id = auth.uid())
    AND driver_user_id = (
      SELECT d.user_id
      FROM public.routes r
      JOIN public.drivers_data d ON r.driver_id = d.id
      WHERE r.id = route_id
    )
    AND (
      -- If student is inserting, they must have an active subscription for this route
      (student_id = auth.uid() AND EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE student_id = auth.uid() AND route_id = conversations.route_id AND status = 'active'
      ))
      -- If driver is inserting, they must have an active subscription from the student for this route
      OR (driver_user_id = auth.uid() AND EXISTS (
        SELECT 1 FROM public.subscriptions
        WHERE student_id = conversations.student_id AND route_id = conversations.route_id AND status = 'active'
      ))
    )
  );


-- ============================================================
-- Fix #6: Tighter geofencing checks for validate_boarding
-- ============================================================
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
END;
$$;

-- Redefining with actual implementation (with 100m geofence)
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
    SELECT id FROM public.drivers_data WHERE user_id = v_user_id
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
  -- within 100m of the trip's last known location. (Fix #6: reduced from 500m to 100m)
  IF p_lat IS NOT NULL AND p_lng IS NOT NULL
     AND v_trip.last_lat IS NOT NULL AND v_trip.last_lng IS NOT NULL THEN
    v_geo_ok := extensions.ST_DistanceSphere(
      extensions.ST_MakePoint(p_lng, p_lat),
      extensions.ST_MakePoint(v_trip.last_lng, v_trip.last_lat)
    ) <= 100.0;
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


-- Redefining validate_boarding_via_proximity (with 30m geofence)
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

  -- Optional geo verification: ensure student is within 30m of driver. (Fix #6: reduced from 50m to 30m)
  IF p_student_lat IS NOT NULL AND p_student_lng IS NOT NULL
     AND v_trip.last_lat IS NOT NULL AND v_trip.last_lng IS NOT NULL THEN
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


-- ============================================================
-- Fix #7: Create secure admin_resolve_emergency RPC
-- ============================================================
CREATE OR REPLACE FUNCTION public.admin_resolve_emergency(
  p_id UUID,
  p_status TEXT,
  p_notes TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized' USING ERRCODE = 'P0001';
  END IF;

  IF p_status NOT IN ('acknowledged', 'resolved') THEN
    RAISE EXCEPTION 'Invalid status transition' USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.emergency_reports SET
    status = p_status,
    notes = COALESCE(p_notes, notes),
    resolved_at = CASE WHEN p_status = 'resolved' THEN NOW() ELSE resolved_at END,
    resolved_by = CASE WHEN p_status = 'resolved' THEN auth.uid() ELSE resolved_by END
  WHERE id = p_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_resolve_emergency(UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_resolve_emergency(UUID, TEXT, TEXT) TO authenticated;
