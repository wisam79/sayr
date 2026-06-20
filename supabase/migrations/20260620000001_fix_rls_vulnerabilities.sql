-- Migration: 20260620000001_fix_rls_vulnerabilities.sql
-- Description: Fix RLS policies to prevent drivers from updating sensitive fields (is_verified, rating, total_trips on drivers; institution_id, driver_id on routes).
--              Drop direct trips UPDATE policy and implement update_trip_ble_otp RPC.

-- 1. Tighten public.drivers_data RLS to prevent updating rating, is_verified, and total_trips
DROP POLICY IF EXISTS "drivers_update_own" ON public.drivers_data;

CREATE POLICY "drivers_update_own"
  ON public.drivers_data FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (
    user_id = auth.uid() AND
    rating = (SELECT d.rating FROM public.drivers_data d WHERE d.user_id = auth.uid()) AND
    is_verified = (SELECT d.is_verified FROM public.drivers_data d WHERE d.user_id = auth.uid()) AND
    total_trips = (SELECT d.total_trips FROM public.drivers_data d WHERE d.user_id = auth.uid())
  );

-- 2. Drop direct UPDATE policy on public.trips to prevent bypassing state machine/timestamps/reasons
DROP POLICY IF EXISTS "trips_update_own_driver" ON public.trips;

-- 3. Create public.update_trip_ble_otp RPC to allow secure BLE OTP updating by the driver
CREATE OR REPLACE FUNCTION public.update_trip_ble_otp(
  p_trip_id UUID,
  p_otp TEXT,
  p_expires_at TIMESTAMPTZ
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Verify the driver owns this trip
  IF NOT EXISTS (
    SELECT 1 FROM public.trips t
    JOIN public.drivers_data d ON t.driver_id = d.id
    WHERE t.id = p_trip_id
      AND d.user_id = auth.uid()
  ) THEN
    RAISE EXCEPTION 'Not authorized to update BLE OTP for this trip'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.trips
  SET ble_otp = p_otp,
      ble_otp_expires_at = p_expires_at,
      updated_at = NOW()
  WHERE id = p_trip_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_trip_ble_otp(UUID, TEXT, TIMESTAMPTZ)
  TO authenticated;

-- 4. Tighten public.routes RLS to prevent updating institution_id and driver_id
DROP POLICY IF EXISTS "routes_update_own_driver" ON public.routes;

CREATE POLICY "routes_update_own_driver"
  ON public.routes FOR UPDATE
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers_data WHERE user_id = auth.uid())
  )
  WITH CHECK (
    driver_id IN (SELECT id FROM public.drivers_data WHERE user_id = auth.uid()) AND
    (institution_id IS NOT DISTINCT FROM (SELECT r.institution_id FROM public.routes r WHERE r.id = routes.id)) AND
    driver_id = (SELECT r.driver_id FROM public.routes r WHERE r.id = routes.id)
  );
