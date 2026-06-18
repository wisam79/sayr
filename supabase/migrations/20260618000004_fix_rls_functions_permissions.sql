-- Migration: 20260618000004_fix_rls_functions_permissions.sql
-- Description: Grant execute permission on RLS policy helper functions back to authenticated and anon roles.
--              This fixes the "permission denied for function is_admin" error that occurs when RLS policies
--              are evaluated during query planning.

GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, anon;
GRANT EXECUTE ON FUNCTION public.is_driver() TO authenticated, anon;
