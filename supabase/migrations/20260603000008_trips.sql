-- Migration: 20260603000008_trips.sql
-- Description: Daily trip instances (scheduled + actual journey)

CREATE TABLE public.trips (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE RESTRICT,
  status TEXT NOT NULL DEFAULT 'scheduled'
    CHECK (status IN (
      'scheduled', 'driver_waiting', 'in_transit', 'completed', 'absent', 'cancelled'
    )),
  scheduled_at TIMESTAMPTZ NOT NULL,
  started_at TIMESTAMPTZ,
  ended_at TIMESTAMPTZ,
  last_lat NUMERIC(10, 7),
  last_lng NUMERIC(10, 7),
  last_location_update TIMESTAMPTZ,
  cancellation_reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trips_route ON public.trips(route_id);
CREATE INDEX idx_trips_driver ON public.trips(driver_id);
CREATE INDEX idx_trips_status ON public.trips(status);
CREATE INDEX idx_trips_scheduled ON public.trips(scheduled_at);
CREATE INDEX idx_trips_active ON public.trips(status)
  WHERE status IN ('scheduled', 'driver_waiting', 'in_transit');

ALTER TABLE public.trips ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read trips (for tracking)
CREATE POLICY "trips_select_authenticated"
  ON public.trips FOR SELECT
  TO authenticated
  USING (true);

-- Drivers can update their own trips
CREATE POLICY "trips_update_own_driver"
  ON public.trips FOR UPDATE
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  )
  WITH CHECK (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Drivers can create trips for their routes
CREATE POLICY "trips_insert_driver"
  ON public.trips FOR INSERT
  TO authenticated
  WITH CHECK (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Admins can manage all
CREATE POLICY "trips_all_admin"
  ON public.trips FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_trips_updated_at
  BEFORE UPDATE ON public.trips
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();
