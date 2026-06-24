-- Migration: 20260621000003_fix_search_paths.sql
-- Description: Re-define trigger functions to explicitly use SECURITY DEFINER and SET search_path = public, and revoke PUBLIC access for update_trip_ble_otp.

CREATE OR REPLACE FUNCTION public.enforce_support_request_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.response IS DISTINCT FROM OLD.response THEN
      RAISE EXCEPTION 'Cannot modify response' USING ERRCODE = 'P0001';
    END IF;
    IF NEW.assigned_to IS DISTINCT FROM OLD.assigned_to THEN
      RAISE EXCEPTION 'Cannot modify assigned_to' USING ERRCODE = 'P0001';
    END IF;
    IF NEW.responded_at IS DISTINCT FROM OLD.responded_at THEN
      RAISE EXCEPTION 'Cannot modify responded_at' USING ERRCODE = 'P0001';
    END IF;
    IF OLD.status = 'closed' AND NEW.status != 'closed' THEN
      RAISE EXCEPTION 'Cannot reopen closed ticket' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

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
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Revoke execute from public on update_trip_ble_otp
REVOKE EXECUTE ON FUNCTION public.update_trip_ble_otp(UUID, TEXT, TIMESTAMPTZ) FROM PUBLIC, anon;
