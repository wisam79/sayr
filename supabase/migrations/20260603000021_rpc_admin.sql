-- Migration: 20260603000021_rpc_admin.sql
-- Description: Admin RPCs for license batches and dashboard

-- Create a license batch (admin only)
CREATE OR REPLACE FUNCTION public.create_license_batch(
  p_route_id UUID,
  p_batch_name TEXT,
  p_quantity INTEGER,
  p_price NUMERIC,
  p_valid_days INTEGER
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_batch_id UUID;
  v_i INTEGER;
  v_code TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_quantity <= 0 OR p_quantity > 10000 THEN
    RAISE EXCEPTION 'Quantity must be between 1 and 10000'
      USING ERRCODE = 'P0001';
  END IF;

  -- Create batch
  INSERT INTO public.license_batches (
    created_by, route_id, batch_name, quantity, price, valid_days
  )
  VALUES (
    auth.uid(), p_route_id, p_batch_name, p_quantity, p_price, p_valid_days
  )
  RETURNING id INTO v_batch_id;

  -- Generate license codes
  FOR v_i IN 1..p_quantity LOOP
    -- Generate random 8-character code
    v_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));

    -- Ensure uniqueness (very rare collision)
    WHILE EXISTS (SELECT 1 FROM public.licenses WHERE code = v_code) LOOP
      v_code := upper(substring(md5(random()::text || clock_timestamp()::text) from 1 for 8));
    END LOOP;

    INSERT INTO public.licenses (batch_id, route_id, code, valid_days, status)
    VALUES (v_batch_id, p_route_id, v_code, p_valid_days, 'active');
  END LOOP;

  -- Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'license_batch_created',
    'license_batch',
    v_batch_id,
    jsonb_build_object('quantity', p_quantity, 'batch_name', p_batch_name)
  );

  RETURN v_batch_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_license_batch(
  UUID, TEXT, INTEGER, NUMERIC, INTEGER
) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_license_batch(
  UUID, TEXT, INTEGER, NUMERIC, INTEGER
) TO authenticated;

-- Get dashboard statistics (admin only)
CREATE OR REPLACE FUNCTION public.get_dashboard_stats()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stats JSONB;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT jsonb_build_object(
    'total_users', (SELECT COUNT(*) FROM public.profiles),
    'total_drivers', (SELECT COUNT(*) FROM public.drivers WHERE is_verified = true),
    'total_routes', (SELECT COUNT(*) FROM public.routes WHERE is_active = true),
    'active_subscriptions', (SELECT COUNT(*) FROM public.subscriptions WHERE status = 'active'),
    'total_trips_today', (
      SELECT COUNT(*) FROM public.trips
      WHERE scheduled_at::date = CURRENT_DATE
    ),
    'total_revenue', (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.payments
      WHERE status = 'completed'
    ),
    'pending_payouts', (
      SELECT COUNT(*) FROM public.driver_payouts WHERE status = 'pending'
    ),
    'pending_payouts_amount', (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.driver_payouts
      WHERE status = 'pending'
    )
  ) INTO v_stats;

  RETURN v_stats;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_dashboard_stats() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_dashboard_stats() TO authenticated;

-- Ping function (for health check)
CREATE OR REPLACE FUNCTION public.ping()
RETURNS JSONB
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT jsonb_build_object('status', 'ok', 'timestamp', NOW());
$$;

GRANT EXECUTE ON FUNCTION public.ping() TO anon, authenticated;

-- Create trip (driver)
CREATE OR REPLACE FUNCTION public.create_trip(
  p_route_id UUID,
  p_scheduled_at TIMESTAMPTZ
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver_id UUID;
  v_trip_id UUID;
BEGIN
  -- Get the driver's record
  SELECT id INTO v_driver_id
  FROM public.drivers
  WHERE user_id = auth.uid();

  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'Not a driver'
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify the route belongs to this driver
  IF NOT EXISTS (
    SELECT 1 FROM public.routes
    WHERE id = p_route_id AND driver_id = v_driver_id
  ) THEN
    RAISE EXCEPTION 'Route does not belong to this driver'
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.trips (route_id, driver_id, scheduled_at, status)
  VALUES (p_route_id, v_driver_id, p_scheduled_at, 'scheduled')
  RETURNING id INTO v_trip_id;

  RETURN v_trip_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.create_trip(UUID, TIMESTAMPTZ) TO authenticated;

-- Admin cancel trip
CREATE OR REPLACE FUNCTION public.admin_cancel_trip(
  p_trip_id UUID,
  p_reason TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.trips
  SET status = 'cancelled',
      cancellation_reason = p_reason,
      ended_at = NOW(),
      updated_at = NOW()
  WHERE id = p_trip_id
    AND status IN ('scheduled', 'driver_waiting', 'in_transit', 'absent');

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Trip not found or already terminal'
      USING ERRCODE = 'P0001';
  END IF;

  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'trip_cancelled_by_admin',
    'trip',
    p_trip_id,
    jsonb_build_object('reason', p_reason)
  );
END;
$$;

REVOKE EXECUTE ON FUNCTION public.admin_cancel_trip(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.admin_cancel_trip(UUID, TEXT) TO authenticated;

-- Get driver statistics (admin only)
CREATE OR REPLACE FUNCTION public.get_driver_stats(
  p_driver_id UUID,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_stats JSONB;
  v_start DATE := COALESCE(p_start_date, CURRENT_DATE - INTERVAL '30 days');
  v_end DATE := COALESCE(p_end_date, CURRENT_DATE);
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  SELECT jsonb_build_object(
    'driver_id', p_driver_id,
    'period', jsonb_build_object('start', v_start, 'end', v_end),
    'total_trips', COALESCE(cts.count, 0),
    'completed_trips', COALESCE(cts.completed, 0),
    'cancelled_trips', COALESCE(cts.cancelled, 0),
    'total_earnings', COALESCE(e.amount, 0),
    'avg_rating', COALESCE(r.avg_rating, 0),
    'total_ratings', COALESCE(r.total_ratings, 0)
  ) INTO v_stats
  FROM (VALUES (1)) AS dummy
  LEFT JOIN (
    SELECT
      driver_id,
      COUNT(*) AS count,
      COUNT(*) FILTER (WHERE status = 'completed') AS completed,
      COUNT(*) FILTER (WHERE status = 'cancelled') AS cancelled
    FROM trips
    WHERE driver_id = p_driver_id
      AND scheduled_at BETWEEN v_start AND v_end
    GROUP BY driver_id
  ) cts ON cts.driver_id = p_driver_id
  LEFT JOIN (
    SELECT driver_id, SUM(total_amount) AS amount
    FROM payouts
    WHERE driver_id = p_driver_id
      AND created_at BETWEEN v_start AND v_end
    GROUP BY driver_id
  ) e ON e.driver_id = p_driver_id
  LEFT JOIN (
    SELECT driver_id, AVG(rating)::NUMERIC AS avg_rating, COUNT(*) AS total_ratings
    FROM ratings
    WHERE driver_id = p_driver_id
      AND created_at BETWEEN v_start AND v_end
    GROUP BY driver_id
  ) r ON r.driver_id = p_driver_id;

  RETURN v_stats;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.get_driver_stats(UUID, DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.get_driver_stats(UUID, DATE, DATE) TO authenticated;
