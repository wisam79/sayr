-- Migration: 20260603000018_rate_limits.sql
-- Description: Rate limiting for sensitive operations (RPC-access only)

CREATE TABLE public.rate_limits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL,
  action TEXT NOT NULL,
  count INTEGER NOT NULL DEFAULT 1,
  window_start TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_rate_limit_user_action UNIQUE (user_id, action, window_start)
);

CREATE INDEX idx_rate_limits_user_action ON public.rate_limits(user_id, action);
CREATE INDEX idx_rate_limits_expires ON public.rate_limits(expires_at);

-- No RLS policies on this table - access only via RPC
ALTER TABLE public.rate_limits ENABLE ROW LEVEL SECURITY;

-- RPC: Check and update rate limit
-- SECURITY: Only callable by service_role to prevent bypassing
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_limit INTEGER,
  p_window_seconds INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
BEGIN
  -- Use a fixed window starting at the beginning of the current minute
  v_window_start := date_trunc('minute', NOW());

  -- Get or create the rate limit record
  INSERT INTO public.rate_limits (user_id, action, count, window_start, expires_at)
  VALUES (
    p_user_id,
    p_action,
    1,
    v_window_start,
    v_window_start + (p_window_seconds || ' seconds')::interval
  )
  ON CONFLICT (user_id, action, window_start)
  DO UPDATE SET count = rate_limits.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= p_limit;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INTEGER, INTEGER)
  FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.check_rate_limit(UUID, TEXT, INTEGER, INTEGER)
  TO service_role;
