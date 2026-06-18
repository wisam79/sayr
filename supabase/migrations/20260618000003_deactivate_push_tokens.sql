-- Migration: 20260618000003_deactivate_push_tokens.sql
-- Description: RPC to deactivate all push tokens for the current user on logout.
--              Prevents stale FCM tokens from receiving push notifications
--              after the user has signed out.

CREATE OR REPLACE FUNCTION public.deactivate_push_tokens()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.push_tokens
  SET is_active = false
  WHERE user_id = auth.uid()
    AND is_active = true;
END;
$$;

-- Only authenticated users may call this.
REVOKE EXECUTE ON FUNCTION public.deactivate_push_tokens() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.deactivate_push_tokens() TO authenticated;
