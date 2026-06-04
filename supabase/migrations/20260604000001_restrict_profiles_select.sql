-- Migration: 20260604000001_restrict_profiles_select.sql
-- Description: Restrict profiles SELECT to prevent leaking phone + fcm_token
-- SECURITY: Public profile view excludes sensitive fields (phone, fcm_token)
-- Users can only see their own full profile via the "own" policy

-- Create a public-safe profile view (excludes phone and fcm_token)
CREATE OR REPLACE VIEW public.profiles_public AS
SELECT
  id,
  full_name,
  role,
  institution_id,
  is_verified,
  avatar_url,
  locale,
  created_at,
  updated_at
FROM public.profiles;

-- Enable RLS on the view (for consistency, though views inherit from base table)
ALTER VIEW public.profiles_public SET (security_invoker = true);

-- Drop the overly broad authenticated SELECT policy
DROP POLICY IF EXISTS "profiles_select_authenticated" ON public.profiles;

-- Replace with a restricted policy: authenticated users can only read
-- the safe fields via the view. For direct table access, they only
-- see their own row (already covered by "profiles_select_own").
-- Admins and drivers who need phone for coordination get it via RPC.
CREATE POLICY "profiles_select_authenticated"
  ON public.profiles FOR SELECT
  TO authenticated
  USING (
    -- Users can see other profiles, but sensitive fields (phone, fcm_token)
    -- are only accessible via the profiles_public view or own profile.
    -- This policy still allows SELECT on the table, but the app should
    -- use the view for non-own profiles.
    auth.uid() = id OR public.is_admin() OR public.is_driver()
  );

-- Grant SELECT on the public view to authenticated users
GRANT SELECT ON public.profiles_public TO authenticated;
