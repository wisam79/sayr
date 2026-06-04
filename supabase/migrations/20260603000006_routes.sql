-- Migration: 20260603000006_routes.sql
-- Description: Bus routes (start → end with stops)

CREATE TABLE public.routes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE RESTRICT,
  institution_id UUID REFERENCES public.institutions(id) ON DELETE SET NULL,
  title TEXT NOT NULL,
  start_location TEXT NOT NULL,
  end_location TEXT NOT NULL,
  start_lat NUMERIC(10, 7),
  start_lng NUMERIC(10, 7),
  end_lat NUMERIC(10, 7),
  end_lng NUMERIC(10, 7),
  price NUMERIC(10, 2) NOT NULL CHECK (price > 0),
  capacity INTEGER NOT NULL CHECK (capacity > 0),
  available_seats INTEGER NOT NULL CHECK (available_seats >= 0),
  departure_time TIME,
  return_time TIME,
  days_of_week TEXT[] NOT NULL DEFAULT ARRAY['sun', 'mon', 'tue', 'wed', 'thu'],
  is_active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- Ensure available_seats never exceeds capacity
  CONSTRAINT chk_seats_capacity CHECK (available_seats <= capacity)
);

CREATE INDEX idx_routes_active ON public.routes(is_active) WHERE is_active = true;
CREATE INDEX idx_routes_driver ON public.routes(driver_id);
CREATE INDEX idx_routes_institution ON public.routes(institution_id);

ALTER TABLE public.routes ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read active routes
CREATE POLICY "routes_select_active"
  ON public.routes FOR SELECT
  TO authenticated
  USING (is_active = true);

-- Drivers can read their own routes (active or not)
CREATE POLICY "routes_select_own_driver"
  ON public.routes FOR SELECT
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Drivers can update their own routes
CREATE POLICY "routes_update_own_driver"
  ON public.routes FOR UPDATE
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  )
  WITH CHECK (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Admins can manage all
CREATE POLICY "routes_all_admin"
  ON public.routes FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_routes_updated_at
  BEFORE UPDATE ON public.routes
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
