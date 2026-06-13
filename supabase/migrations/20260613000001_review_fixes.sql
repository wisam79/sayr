-- Migration: 20260613000001_review_fixes.sql
-- Description: Fixes from comprehensive multi-skill code review.
--   DB-1: Composite index on push_tokens(user_id, is_active)
--   DB-2: Fix cancel_subscription service-role compatibility
--   DB-4: pg_cron job to purge expired rate_limits records

-- ============================================================
-- DB-1: Add composite index for efficient push token lookups.
-- The send-push-notification Edge Function queries by (user_id, is_active)
-- on every notification dispatch.
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_push_tokens_user_active
  ON public.push_tokens (user_id, is_active)
  WHERE is_active = true;


-- ============================================================
-- DB-2: Fix cancel_subscription to work when called from
-- service_role context (auth.uid() returns NULL).
-- The process-payment Edge Function calls this via admin client
-- when a payment fails and needs to release the seat.
-- ============================================================
CREATE OR REPLACE FUNCTION public.cancel_subscription(
  p_subscription_id UUID
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_sub RECORD;
  v_is_service_role BOOLEAN;
BEGIN
  -- Detect service_role context (auth.uid() is NULL for service_role)
  v_is_service_role := (auth.uid() IS NULL);

  -- Lock the subscription
  SELECT * INTO v_sub
  FROM public.subscriptions
  WHERE id = p_subscription_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Subscription not found'
      USING ERRCODE = 'P0001';
  END IF;

  -- Only the owner, admin, or service_role can cancel
  IF NOT v_is_service_role
     AND v_sub.student_id != auth.uid()
     AND NOT public.is_admin()
  THEN
    RAISE EXCEPTION 'Not authorized'
      USING ERRCODE = 'P0001';
  END IF;

  -- Already cancelled?
  IF v_sub.status = 'cancelled' THEN
    RETURN;
  END IF;

  -- Update subscription
  UPDATE public.subscriptions
  SET status = 'cancelled',
      cancelled_at = NOW(),
      updated_at = NOW()
  WHERE id = p_subscription_id;

  -- Return seat to route (for active and pending subscriptions)
  IF v_sub.status IN ('active', 'pending') THEN
    UPDATE public.routes
    SET available_seats = LEAST(capacity, available_seats + 1),
        updated_at = NOW()
    WHERE id = v_sub.route_id;
  END IF;
END;
$$;


-- ============================================================
-- DB-4: Cleanup function for expired rate_limits records.
-- Rate limit records accumulate forever without cleanup.
-- This function purges all records whose window has expired.
-- ============================================================
CREATE OR REPLACE FUNCTION public.cleanup_expired_rate_limits()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  DELETE FROM public.rate_limits
  WHERE expires_at < NOW();

  GET DIAGNOSTICS v_count = ROW_COUNT;

  INSERT INTO public.cron_health (job_name, last_run_at, rows_affected)
  VALUES ('cleanup_rate_limits_job', NOW(), v_count)
  ON CONFLICT (job_name)
  DO UPDATE SET last_run_at = NOW(), rows_affected = v_count;
END;
$$;

-- Schedule cleanup every hour
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'cleanup_rate_limits_job';
SELECT cron.schedule('cleanup_rate_limits_job', '0 * * * *', 'SELECT public.cleanup_expired_rate_limits();');
