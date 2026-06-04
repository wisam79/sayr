-- Migration: 20260603000017_app_config.sql
-- Description: App-wide configuration (force update, maintenance, etc.)

CREATE TABLE public.app_config (
  id INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
  min_version TEXT NOT NULL DEFAULT '3.0.0',
  latest_version TEXT NOT NULL DEFAULT '3.0.0',
  update_url TEXT,
  maintenance_mode BOOLEAN NOT NULL DEFAULT false,
  maintenance_message TEXT,
  maintenance_message_en TEXT,
  support_email TEXT,
  support_phone TEXT,
  terms_url TEXT,
  privacy_url TEXT,
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_by UUID REFERENCES public.profiles(id)
);

-- Seed default config
INSERT INTO public.app_config (id, min_version, latest_version, support_email)
VALUES (1, '3.0.0', '3.0.0', 'support@sayr.app')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.app_config ENABLE ROW LEVEL SECURITY;

-- Everyone can read config
CREATE POLICY "app_config_select_all"
  ON public.app_config FOR SELECT
  USING (true);

-- Only admins can update
CREATE POLICY "app_config_update_admin"
  ON public.app_config FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_app_config_updated_at
  BEFORE UPDATE ON public.app_config
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- RPC: Get app config (bypasses RLS for anon)
CREATE OR REPLACE FUNCTION public.get_app_config()
RETURNS public.app_config
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT * FROM public.app_config WHERE id = 1;
$$;

GRANT EXECUTE ON FUNCTION public.get_app_config() TO anon, authenticated;
