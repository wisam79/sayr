-- Migration: 20260603000009_licenses.sql
-- Description: License codes (prepaid vouchers for route subscriptions)

CREATE TABLE public.license_batches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by UUID NOT NULL REFERENCES public.profiles(id),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  batch_name TEXT NOT NULL,
  quantity INTEGER NOT NULL CHECK (quantity > 0),
  price NUMERIC(10, 2) NOT NULL CHECK (price >= 0),
  valid_days INTEGER NOT NULL CHECK (valid_days > 0),
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_license_batches_route ON public.license_batches(route_id);
CREATE INDEX idx_license_batches_created ON public.license_batches(created_by);

CREATE TABLE public.licenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  batch_id UUID NOT NULL REFERENCES public.license_batches(id) ON DELETE CASCADE,
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  code CHAR(8) NOT NULL UNIQUE
    CHECK (code ~ '^[A-Z0-9]{8}$'),
  status TEXT NOT NULL DEFAULT 'active'
    CHECK (status IN ('active', 'used', 'expired', 'revoked')),
  valid_days INTEGER NOT NULL CHECK (valid_days > 0),
  used_by UUID REFERENCES public.profiles(id),
  used_at TIMESTAMPTZ,
  expires_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_licenses_code ON public.licenses(code);
CREATE INDEX idx_licenses_status ON public.licenses(status);
CREATE INDEX idx_licenses_batch ON public.licenses(batch_id);
CREATE INDEX idx_licenses_used_by ON public.licenses(used_by);

ALTER TABLE public.license_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.licenses ENABLE ROW LEVEL SECURITY;

-- License batches: only admins can manage
CREATE POLICY "license_batches_all_admin"
  ON public.license_batches FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Drivers can see their batches (informational)
CREATE POLICY "license_batches_select_driver"
  ON public.license_batches FOR SELECT
  TO authenticated
  USING (
    route_id IN (
      SELECT r.id FROM public.routes r
      JOIN public.drivers d ON r.driver_id = d.id
      WHERE d.user_id = auth.uid()
    )
  );

-- Licenses: only admins can read all (security-sensitive)
CREATE POLICY "licenses_all_admin"
  ON public.licenses FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Users can see their own used licenses
CREATE POLICY "licenses_select_own_used"
  ON public.licenses FOR SELECT
  TO authenticated
  USING (used_by = auth.uid());

-- Now add FK from subscriptions to licenses
ALTER TABLE public.subscriptions
  ADD CONSTRAINT fk_subscriptions_license
  FOREIGN KEY (license_id) REFERENCES public.licenses(id) ON DELETE SET NULL;
