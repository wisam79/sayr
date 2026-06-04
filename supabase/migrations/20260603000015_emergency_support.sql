-- Migration: 20260603000015_emergency_support.sql
-- Description: Emergency reports (SOS) and support requests

CREATE TABLE public.emergency_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  latitude NUMERIC(10, 7) NOT NULL,
  longitude NUMERIC(10, 7) NOT NULL,
  message TEXT,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'acknowledged', 'resolved')),
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES public.profiles(id),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_emergency_user ON public.emergency_reports(user_id);
CREATE INDEX idx_emergency_trip ON public.emergency_reports(trip_id);
CREATE INDEX idx_emergency_status ON public.emergency_reports(status);
CREATE INDEX idx_emergency_created ON public.emergency_reports(created_at DESC);

ALTER TABLE public.emergency_reports ENABLE ROW LEVEL SECURITY;

-- Users can create their own emergency reports
CREATE POLICY "emergency_insert_own"
  ON public.emergency_reports FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Users can read their own reports
CREATE POLICY "emergency_select_own"
  ON public.emergency_reports FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Admins can manage all
CREATE POLICY "emergency_all_admin"
  ON public.emergency_reports FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TABLE public.support_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'open'
    CHECK (status IN ('open', 'in_progress', 'closed')),
  assigned_to UUID REFERENCES public.profiles(id),
  response TEXT,
  responded_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_support_user ON public.support_requests(user_id);
CREATE INDEX idx_support_status ON public.support_requests(status);
CREATE INDEX idx_support_created ON public.support_requests(created_at DESC);

ALTER TABLE public.support_requests ENABLE ROW LEVEL SECURITY;

-- Users can manage their own support requests
CREATE POLICY "support_all_own"
  ON public.support_requests FOR ALL
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Admins can read and update all
CREATE POLICY "support_admin_all"
  ON public.support_requests FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_support_updated_at
  BEFORE UPDATE ON public.support_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
