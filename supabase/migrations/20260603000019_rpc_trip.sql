-- Migration: 20260603000019_rpc_trip.sql
-- Description: Trip state machine RPCs (validates transitions)

-- Valid trip status transitions
-- scheduled → driver_waiting, absent, cancelled
-- driver_waiting → in_transit, absent, cancelled
-- in_transit → completed, cancelled
-- absent → cancelled
-- completed, cancelled are terminal

CREATE OR REPLACE FUNCTION public.update_trip_status(
  p_trip_id UUID,
  p_new_status TEXT,
  p_lat NUMERIC DEFAULT NULL,
  p_lng NUMERIC DEFAULT NULL
)
RETURNS public.trips
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_trip RECORD;
  v_valid BOOLEAN := false;
BEGIN
  -- Lock the trip
  SELECT * INTO v_trip
  FROM public.trips
  WHERE id = p_trip_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trip not found'
      USING ERRCODE = 'P0001';
  END IF;

  -- Validate state transition
  v_valid := CASE
    WHEN v_trip.status = 'scheduled' AND p_new_status IN ('driver_waiting', 'absent', 'cancelled') THEN true
    WHEN v_trip.status = 'driver_waiting' AND p_new_status IN ('in_transit', 'absent', 'cancelled') THEN true
    WHEN v_trip.status = 'in_transit' AND p_new_status IN ('completed', 'cancelled') THEN true
    WHEN v_trip.status = 'absent' AND p_new_status = 'cancelled' THEN true
    ELSE false
  END;

  IF NOT v_valid THEN
    RAISE EXCEPTION 'Invalid status transition: % → %', v_trip.status, p_new_status
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify the driver owns this trip
  IF v_trip.driver_id NOT IN (
    SELECT id FROM public.drivers WHERE user_id = auth.uid()
  ) AND NOT public.is_admin() THEN
    RAISE EXCEPTION 'Not authorized to update this trip'
      USING ERRCODE = 'P0001';
  END IF;

  -- Update the trip
  UPDATE public.trips
  SET status = p_new_status,
      last_lat = COALESCE(p_lat, last_lat),
      last_lng = COALESCE(p_lng, last_lng),
      last_location_update = CASE WHEN p_lat IS NOT NULL THEN NOW() ELSE last_location_update END,
      started_at = CASE
        WHEN p_new_status = 'in_transit' AND started_at IS NULL THEN NOW()
        ELSE started_at
      END,
      ended_at = CASE
        WHEN p_new_status IN ('completed', 'cancelled') THEN NOW()
        ELSE ended_at
      END,
      updated_at = NOW()
  WHERE id = p_trip_id
  RETURNING * INTO v_trip;

  -- Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'trip_status_changed',
    'trip',
    p_trip_id,
    jsonb_build_object(
      'new_status', p_new_status,
      'lat', p_lat,
      'lng', p_lng
    )
  );

  RETURN v_trip;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_trip_status(UUID, TEXT, NUMERIC, NUMERIC)
  TO authenticated;

-- RPC: Update trip location (no status change)
CREATE OR REPLACE FUNCTION public.update_trip_location(
  p_trip_id UUID,
  p_lat NUMERIC,
  p_lng NUMERIC
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Validate coordinates
  IF p_lat < -90 OR p_lat > 90 OR p_lng < -180 OR p_lng > 180 THEN
    RAISE EXCEPTION 'Invalid coordinates'
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify the driver owns this trip and trip is active
  IF NOT EXISTS (
    SELECT 1 FROM public.trips t
    JOIN public.drivers d ON t.driver_id = d.id
    WHERE t.id = p_trip_id
      AND d.user_id = auth.uid()
      AND t.status IN ('driver_waiting', 'in_transit')
  ) THEN
    RAISE EXCEPTION 'Cannot update location for this trip'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.trips
  SET last_lat = p_lat,
      last_lng = p_lng,
      last_location_update = NOW(),
      updated_at = NOW()
  WHERE id = p_trip_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.update_trip_location(UUID, NUMERIC, NUMERIC)
  TO authenticated;

-- RPC: Bulk update trip locations (for offline sync)
CREATE OR REPLACE FUNCTION public.bulk_update_trip_locations(
  p_locations JSONB
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_loc JSONB;
BEGIN
  FOR v_loc IN SELECT * FROM jsonb_array_elements(p_locations)
  LOOP
    PERFORM public.update_trip_location(
      (v_loc->>'trip_id')::UUID,
      (v_loc->>'lat')::NUMERIC,
      (v_loc->>'lng')::NUMERIC
    );
  END LOOP;
END;
$$;

GRANT EXECUTE ON FUNCTION public.bulk_update_trip_locations(JSONB)
  TO authenticated;
