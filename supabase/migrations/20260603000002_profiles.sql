-- Migration: 20260603000002_profiles.sql
-- Description: Profiles table (1:1 with auth.users)
-- SECURITY: Role is stored in app_metadata only, never user_metadata
-- NOTE: Helper functions is_admin/is_driver/get_my_role defined here
-- because they are needed by RLS policies in this and subsequent migrations.

-- --- Helper functions (must exist before RLS policies) ---
CREATE OR REPLACE FUNCTION public.get_my_role()
RETURNS TEXT AS $$
  SELECT COALESCE(auth.jwt() -> 'app_metadata' ->> 'role', 'student');
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'admin', false);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION public.is_driver()
RETURNS BOOLEAN AS $$
  SELECT COALESCE((auth.jwt() -> 'app_metadata' ->> 'role') = 'driver', false);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name TEXT,
  phone TEXT,
  role TEXT NOT NULL DEFAULT 'student'
    CHECK (role IN ('admin', 'student', 'driver')),
  institution_id UUID,
  is_verified BOOLEAN NOT NULL DEFAULT false,
  avatar_url TEXT,
  fcm_token TEXT,
  locale TEXT NOT NULL DEFAULT 'ar'
    CHECK (locale IN ('ar', 'en')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_role ON public.profiles(role);
CREATE INDEX idx_profiles_institution ON public.profiles(institution_id);

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Users can read their own profile
CREATE POLICY "profiles_select_own"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

-- Users can read other profiles (for driver info, etc.)
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (true);

-- Users can update their own profile (but not role/is_verified)
CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (
    auth.uid() = id
    AND role = (SELECT role FROM public.profiles WHERE id = auth.uid())
    AND is_verified = (SELECT is_verified FROM public.profiles WHERE id = auth.uid())
  );

-- Admins can update any profile
CREATE POLICY "profiles_update_admin"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Updated_at trigger
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;

CREATE TRIGGER set_profiles_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Profile creation on signup (auto-create via trigger on auth.users)
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, phone, role)
  VALUES (
    NEW.id,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'phone',
    COALESCE(NEW.raw_app_meta_data->>'role', 'student')
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();
