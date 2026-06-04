-- Migration: 20260604000004_secure_driver_rls.sql
-- Description: Drop drivers_update_own and recreate it to prevent self-updating rating and is_verified

DROP POLICY IF EXISTS "drivers_update_own" ON public.drivers;

CREATE POLICY "drivers_update_own"
  ON public.drivers FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid() AND
    rating = (SELECT d.rating FROM public.drivers d WHERE d.id = drivers.id) AND
    is_verified = (SELECT d.is_verified FROM public.drivers d WHERE d.id = drivers.id)
  );
