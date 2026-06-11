-- Migration: 20260610000006_keep_osrm_alive.sql
-- Description: Create a SQL function and a pg_cron job to ping the keep-osrm-alive Edge Function every 12 hours.
-- This keeps the Hugging Face private OSRM space active and prevents it from entering sleep mode.

CREATE OR REPLACE FUNCTION public.ping_osrm_space()
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_service_key TEXT;
  v_url TEXT := 'http://kong:8000/functions/v1/keep-osrm-alive';
BEGIN
  -- Retrieve service_role_key from decrypted vault secrets
  SELECT decrypted_secret INTO v_service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  -- Fallback if running locally and service_role_key is not in vault yet
  IF v_service_key IS NULL THEN
    v_service_key := current_setting('request.headers', true)::json ->> 'apikey';
  END If;

  -- Perform keep-alive POST request using pg_net
  PERFORM net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', CONCAT('Bearer ', COALESCE(v_service_key, ''))
    ),
    body := '{}'::text
  );
END;
$$;

REVOKE ALL ON FUNCTION public.ping_osrm_space() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.ping_osrm_space() TO service_role;

-- Schedule pg_cron job to run every 12 hours (unschedule first if exists)
SELECT cron.unschedule(jobname) FROM cron.job WHERE jobname = 'ping_osrm_space_job';
SELECT cron.schedule('ping_osrm_space_job', '0 */12 * * *', 'SELECT public.ping_osrm_space();');
