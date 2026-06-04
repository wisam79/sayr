-- Migration: 20260604000003_fix_admin_rpcs.sql
-- Description: Fix get_driver_stats query and define create_payment RPC

-- 1. Correct get_driver_stats to reference public.driver_payouts and amount
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
    SELECT driver_id, SUM(amount) AS amount
    FROM public.driver_payouts
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

-- 2. Define create_payment RPC to insert a pending payment
CREATE OR REPLACE FUNCTION public.create_payment(
  p_route_id UUID,
  p_amount NUMERIC,
  p_currency TEXT,
  p_method TEXT
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license_id UUID;
  v_valid_days INTEGER;
  v_subscription_id UUID;
  v_status TEXT;
  v_payment public.payments;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated'
      USING ERRCODE = 'P0001';
  END IF;

  -- Validate route
  IF NOT EXISTS (SELECT 1 FROM public.routes WHERE id = p_route_id AND is_active = true) THEN
    RAISE EXCEPTION 'Route not found or inactive'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check existing subscription
  SELECT id, license_id, status INTO v_subscription_id, v_license_id, v_status
  FROM public.subscriptions
  WHERE student_id = auth.uid()
    AND route_id = p_route_id
    AND status IN ('active', 'pending')
  LIMIT 1;

  IF FOUND THEN
    IF v_status = 'active' THEN
      RAISE EXCEPTION 'You already have an active subscription for this route'
        USING ERRCODE = 'P0001';
    END IF;
  ELSE
    -- Find an active, unclaimed license
    SELECT l.id, l.valid_days INTO v_license_id, v_valid_days
    FROM public.licenses l
    WHERE l.route_id = p_route_id
      AND l.status = 'active'
      AND l.used_by IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.subscriptions s
        WHERE s.license_id = l.id
          AND s.status IN ('active', 'pending')
      )
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_license_id IS NULL THEN
      RAISE EXCEPTION 'No licenses available for this route'
        USING ERRCODE = 'P0001';
    END IF;

    -- Create pending subscription
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      p_route_id,
      v_license_id,
      'pending',
      NOW(),
      NOW() + (v_valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;
  END IF;

  -- Create pending payment
  INSERT INTO public.payments (
    user_id,
    subscription_id,
    license_id,
    amount,
    currency,
    method,
    status
  )
  VALUES (
    auth.uid(),
    v_subscription_id,
    v_license_id,
    p_amount,
    p_currency,
    p_method,
    'pending'
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.create_payment(UUID, NUMERIC, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.create_payment(UUID, NUMERIC, TEXT, TEXT) TO authenticated;
