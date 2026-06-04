-- Migration: 20260603000005_drivers.sql
-- Description: Drivers table with role promotion trigger

CREATE TABLE public.drivers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  vehicle_model TEXT NOT NULL,
  vehicle_plate TEXT NOT NULL UNIQUE,
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  license_number TEXT,
  license_expiry DATE,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  rating NUMERIC(3, 2) NOT NULL DEFAULT 0
    CHECK (rating >= 0 AND rating <= 5),
  total_trips INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_drivers_user ON public.drivers(user_id);
CREATE INDEX idx_drivers_verified ON public.drivers(is_verified);
CREATE INDEX idx_drivers_plate ON public.drivers(vehicle_plate);

ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read driver info (public-facing)
CREATE POLICY "drivers_select_authenticated"
  ON public.drivers FOR SELECT
  TO authenticated
  USING (is_verified = true);

-- Drivers can read their own record even if not verified
CREATE POLICY "drivers_select_own"
  ON public.drivers FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Drivers can update their own non-sensitive fields
CREATE POLICY "drivers_update_own"
  ON public.drivers FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admins can manage all
CREATE POLICY "drivers_all_admin"
  ON public.drivers FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_drivers_updated_at
  BEFORE UPDATE ON public.drivers
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Trigger: When a driver is created, promote their role to 'driver'
CREATE OR REPLACE FUNCTION public.sync_driver_role_promotion()
RETURNS TRIGGER AS $$
BEGIN
  -- Update profile role
  UPDATE public.profiles
  SET role = 'driver'
  WHERE id = NEW.user_id AND role != 'driver';

  -- Update app_metadata via auth.users
  UPDATE auth.users
  SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('role', 'driver')
  WHERE id = NEW.user_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_driver_created
  AFTER INSERT ON public.drivers
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_driver_role_promotion();

-- Trigger: When a driver is deleted, demote their role to 'student'
CREATE OR REPLACE FUNCTION public.sync_driver_role_demotion()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.profiles
  SET role = 'student'
  WHERE id = OLD.user_id AND role = 'driver';

  UPDATE auth.users
  SET raw_app_meta_data = COALESCE(raw_app_meta_data, '{}'::jsonb)
    || jsonb_build_object('role', 'student')
  WHERE id = OLD.user_id;

  RETURN OLD;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_driver_deleted
  AFTER DELETE ON public.drivers
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_driver_role_demotion();

-- Revoke trigger function execution from public
REVOKE EXECUTE ON FUNCTION public.sync_driver_role_promotion() FROM PUBLIC, anon, authenticated;
REVOKE EXECUTE ON FUNCTION public.sync_driver_role_demotion() FROM PUBLIC, anon, authenticated;
