-- Migration: 20260610000004_add_get_license_details.sql
-- Description: Add get_license_details RPC to preview license info before activating.

CREATE OR REPLACE FUNCTION public.get_license_details(
  p_code TEXT
)
RETURNS TABLE (
  license_id UUID,
  route_id UUID,
  route_title TEXT,
  start_location TEXT,
  end_location TEXT,
  valid_days INTEGER,
  price NUMERIC,
  available_seats INTEGER,
  status TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license RECORD;
BEGIN
  -- Rate limit: max 10 attempts per 15 minutes
  IF NOT public.check_rate_limit(
    auth.uid(),
    'get_license_details',
    10,
    900
  ) THEN
    RAISE EXCEPTION 'Too many attempts. Please try again later.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Normalize code
  p_code := UPPER(TRIM(p_code));

  -- Validate format
  IF p_code !~ '^[A-Z0-9]{8}$' THEN
    RAISE EXCEPTION 'Invalid license code format'
      USING ERRCODE = 'P0001';
  END IF;

  -- Fetch license details
  SELECT l.id, l.route_id, l.status, l.used_by, l.valid_days
  INTO v_license
  FROM public.licenses l
  WHERE l.code = p_code;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'License code not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.status != 'active' THEN
    RAISE EXCEPTION 'License is not active (status: %)', v_license.status
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.used_by IS NOT NULL THEN
    RAISE EXCEPTION 'License already used'
      USING ERRCODE = 'P0001';
  END IF;

  RETURN QUERY
  SELECT 
    l.id AS license_id,
    l.route_id,
    r.title AS route_title,
    r.start_location,
    r.end_location,
    l.valid_days,
    r.price,
    r.available_seats,
    l.status
  FROM public.licenses l
  JOIN public.routes r ON l.route_id = r.id
  WHERE l.id = v_license.id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_license_details(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_license_details(TEXT) TO authenticated;
