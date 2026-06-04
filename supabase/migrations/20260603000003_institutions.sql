-- Migration: 20260603000003_institutions.sql
-- Description: Universities and educational institutions

CREATE TABLE public.institutions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  city TEXT,
  logo_url TEXT,
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_institutions_active ON public.institutions(is_active);
CREATE INDEX idx_institutions_city ON public.institutions(city);

ALTER TABLE public.institutions ENABLE ROW LEVEL SECURITY;

-- Everyone can read active institutions
CREATE POLICY "institutions_select_active"
  ON public.institutions FOR SELECT
  USING (is_active = true);

-- Admins can manage
CREATE POLICY "institutions_all_admin"
  ON public.institutions FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_institutions_updated_at
  BEFORE UPDATE ON public.institutions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- Add foreign key from profiles to institutions
ALTER TABLE public.profiles
  ADD CONSTRAINT fk_profiles_institution
  FOREIGN KEY (institution_id) REFERENCES public.institutions(id) ON DELETE SET NULL;
