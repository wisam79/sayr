-- Migration: 20260603000007_subscriptions.sql
-- Description: Student subscriptions to routes

CREATE TABLE public.subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'pending', 'expired', 'cancelled')),
  start_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  end_date TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancel_reason TEXT,
  license_id UUID, -- FK added later
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_student ON public.subscriptions(student_id);
CREATE INDEX idx_subscriptions_route ON public.subscriptions(route_id);
CREATE INDEX idx_subscriptions_status ON public.subscriptions(status);
CREATE INDEX idx_subscriptions_end_date ON public.subscriptions(end_date);

-- CRITICAL: Prevent duplicate active subscriptions for same (student, route)
-- This is one layer of race condition protection
CREATE UNIQUE INDEX idx_one_active_sub_per_route
  ON public.subscriptions(student_id, route_id)
  WHERE status IN ('active', 'pending');

ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;

-- Students can read their own subscriptions
CREATE POLICY "subscriptions_select_own"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Drivers can read subscriptions for their routes
CREATE POLICY "subscriptions_select_driver"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (
    route_id IN (
      SELECT r.id FROM public.routes r
      JOIN public.drivers d ON r.driver_id = d.id
      WHERE d.user_id = auth.uid()
    )
  );

-- Admins can read all
CREATE POLICY "subscriptions_select_admin"
  ON public.subscriptions FOR SELECT
  TO authenticated
  USING (public.is_admin());

CREATE TRIGGER set_subscriptions_updated_at
  BEFORE UPDATE ON public.subscriptions
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
