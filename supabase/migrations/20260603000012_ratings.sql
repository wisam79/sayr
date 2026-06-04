-- Migration: 20260603000012_ratings.sql
-- Description: Trip ratings

CREATE TABLE public.ratings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  trip_id UUID NOT NULL REFERENCES public.trips(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One rating per (trip, student)
  CONSTRAINT uq_rating_per_trip_student UNIQUE (trip_id, student_id)
);

CREATE INDEX idx_ratings_trip ON public.ratings(trip_id);
CREATE INDEX idx_ratings_driver ON public.ratings(driver_id);
CREATE INDEX idx_ratings_student ON public.ratings(student_id);
CREATE INDEX idx_ratings_created ON public.ratings(created_at DESC);

ALTER TABLE public.ratings ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read ratings
CREATE POLICY "ratings_select_authenticated"
  ON public.ratings FOR SELECT
  TO authenticated
  USING (true);

-- Students can create ratings for their own trips
CREATE POLICY "ratings_insert_own_student"
  ON public.ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      JOIN public.trips t ON t.route_id = s.route_id
      WHERE s.student_id = auth.uid()
        AND t.id = trip_id
    )
  );

-- Trigger: Update driver's average rating
CREATE OR REPLACE FUNCTION public.sync_driver_rating()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.drivers
  SET rating = (
    SELECT COALESCE(AVG(rating)::numeric(3, 2), 0)
    FROM public.ratings
    WHERE driver_id = NEW.driver_id
  ),
  total_trips = (
    SELECT COUNT(DISTINCT trip_id)
    FROM public.ratings
    WHERE driver_id = NEW.driver_id
  )
  WHERE id = NEW.driver_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER on_rating_created
  AFTER INSERT ON public.ratings
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_driver_rating();

REVOKE EXECUTE ON FUNCTION public.sync_driver_rating() FROM PUBLIC, anon, authenticated;
