-- Migration: 20260603000014_notifications.sql
-- Description: Push tokens and notification log

CREATE TABLE public.push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('android', 'ios', 'web')),
  device_id TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  last_seen_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CONSTRAINT uq_push_token UNIQUE (user_id, token)
);

CREATE INDEX idx_push_tokens_user ON public.push_tokens(user_id);
CREATE INDEX idx_push_tokens_active ON public.push_tokens(is_active) WHERE is_active = true;

ALTER TABLE public.push_tokens ENABLE ROW LEVEL SECURITY;

-- Users can manage their own tokens
CREATE POLICY "push_tokens_all_own"
  ON public.push_tokens FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Service role can read all (for sending)
CREATE POLICY "push_tokens_select_service"
  ON public.push_tokens FOR SELECT
  TO service_role
  USING (true);

CREATE TABLE public.notification_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  data JSONB NOT NULL DEFAULT '{}'::jsonb,
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  sent_at TIMESTAMPTZ,
  error TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notification_log_user ON public.notification_log(user_id);
CREATE INDEX idx_notification_log_unread ON public.notification_log(user_id, is_read)
  WHERE is_read = false;
CREATE INDEX idx_notification_log_created ON public.notification_log(created_at DESC);

ALTER TABLE public.notification_log ENABLE ROW LEVEL SECURITY;

-- Users can read their own notifications
CREATE POLICY "notification_log_select_own"
  ON public.notification_log FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can mark their notifications as read
CREATE POLICY "notification_log_update_own"
  ON public.notification_log FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- RPC: Register push token
CREATE OR REPLACE FUNCTION public.register_push_token(
  p_token TEXT,
  p_platform TEXT,
  p_device_id TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_id UUID;
BEGIN
  INSERT INTO public.push_tokens (user_id, token, platform, device_id, last_seen_at)
  VALUES (auth.uid(), p_token, p_platform, p_device_id, NOW())
  ON CONFLICT (user_id, token)
  DO UPDATE SET
    is_active = true,
    last_seen_at = NOW()
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$$;

GRANT EXECUTE ON FUNCTION public.register_push_token(TEXT, TEXT, TEXT) TO authenticated;
