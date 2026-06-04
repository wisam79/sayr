-- Migration: 20260603000022_seed.sql
-- ⚠️ WARNING: DEV / STAGING ONLY - DO NOT RUN IN PRODUCTION
-- Description: Seed data for development and testing
-- Creates test users, institutions, drivers, routes, and license batches

-- Only run this in dev/staging environments
DO $$
BEGIN
  IF current_setting('environment', true) = 'production' THEN
    RAISE EXCEPTION 'Seed data cannot be loaded in production';
  END IF;
END $$;

-- Create test institutions
INSERT INTO public.institutions (id, name, city) VALUES
  ('00000000-0000-0000-0000-000000000001', 'جامعة بغداد', 'بغداد'),
  ('00000000-0000-0000-0000-000000000002', 'الجامعة المستنصرية', 'بغداد'),
  ('00000000-0000-0000-0000-000000000003', 'جامعة البصرة', 'البصرة')
ON CONFLICT (id) DO NOTHING;

-- Note: To create test users, drivers, and routes, you need to:
-- 1. Create auth.users via Supabase Auth API (signup)
-- 2. Then create corresponding profiles, drivers, routes
--
-- Use the Supabase Studio or API to create test users:
--   - admin@sayr.app (role: admin) - password: AdminTest123!
--   - driver@sayr.app (role: driver) - password: DriverTest123!
--   - student@sayr.app (role: student) - password: StudentTest123!
--
-- After creating auth users, the handle_new_user trigger will auto-create profiles.
-- Then you can manually promote to driver/admin via:
--   UPDATE public.profiles SET role = 'admin' WHERE id = '...';
--   INSERT INTO public.drivers (user_id, vehicle_model, vehicle_plate, capacity) VALUES (...);

-- Helper: Get environment variable in Supabase
COMMENT ON TABLE public.institutions IS
  'Universities and educational institutions. Test data in dev/staging only.';
