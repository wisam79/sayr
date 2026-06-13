-- Add a lightweight cron health check table
CREATE TABLE IF NOT EXISTS public.cron_health (
  job_name TEXT PRIMARY KEY,
  last_run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  rows_affected INTEGER NOT NULL DEFAULT 0
);

ALTER TABLE public.cron_health ENABLE ROW LEVEL SECURITY;

-- Only admin and service_role can read/write
CREATE POLICY "cron_health_admin"
  ON public.cron_health FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE POLICY "cron_health_service"
  ON public.cron_health FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

-- Modify expire_subscriptions to log health
CREATE OR REPLACE FUNCTION public.expire_subscriptions_and_return_seats()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_sub IN
    UPDATE public.subscriptions
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active' AND end_date <= NOW()
    RETURNING route_id, license_id
  LOOP
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1), updated_at = NOW()
    WHERE id = v_sub.route_id;

    IF v_sub.license_id IS NOT NULL THEN
      UPDATE public.licenses SET status = 'expired' WHERE id = v_sub.license_id;
    END IF;

    v_count := v_count + 1;
  END LOOP;

  INSERT INTO public.cron_health (job_name, last_run_at, rows_affected)
  VALUES ('expire_subscriptions_job', NOW(), v_count)
  ON CONFLICT (job_name)
  DO UPDATE SET last_run_at = NOW(), rows_affected = v_count;
END;
$$;

-- Same for reclaim_pending_reservations
CREATE OR REPLACE FUNCTION public.reclaim_pending_reservations()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
  v_count INTEGER := 0;
BEGIN
  FOR v_sub IN
    UPDATE public.subscriptions
    SET status = 'cancelled',
        cancel_reason = 'Payment timeout (15 minutes)',
        updated_at = NOW()
    WHERE status = 'pending'
      AND created_at <= NOW() - INTERVAL '15 minutes'
    RETURNING id, route_id
  LOOP
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1), updated_at = NOW()
    WHERE id = v_sub.route_id;

    UPDATE public.payments
    SET status = 'failed',
        metadata = metadata || '{"failure_reason": "Payment timeout (15 minutes)"}'::jsonb,
        updated_at = NOW()
    WHERE subscription_id = v_sub.id AND status = 'pending';

    v_count := v_count + 1;
  END LOOP;

  INSERT INTO public.cron_health (job_name, last_run_at, rows_affected)
  VALUES ('reclaim_pending_reservations_job', NOW(), v_count)
  ON CONFLICT (job_name)
  DO UPDATE SET last_run_at = NOW(), rows_affected = v_count;
END;
$$;
