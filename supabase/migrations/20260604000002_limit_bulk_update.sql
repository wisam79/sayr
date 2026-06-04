-- Migration: 20260604000002_limit_bulk_update.sql
-- Description: Add batch size limit to bulk_update_trip_locations RPC
-- SECURITY: Prevents abuse via oversized bulk update requests (max 100 records)

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
  v_count INTEGER;
BEGIN
  -- Enforce maximum batch size of 100 records
  v_count := jsonb_array_length(p_locations);

  IF v_count > 100 THEN
    RAISE EXCEPTION 'Batch size exceeds maximum of 100 records (got %)', v_count
      USING ERRCODE = 'P0001';
  END IF;

  IF v_count = 0 THEN
    RETURN;
  END IF;

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
