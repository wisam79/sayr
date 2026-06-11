-- Backfill: Populate geometry for existing routes
-- 
-- Run after adding geometry column to fill in geometries for routes
-- that were already in the system.
--
-- Since Postgres can't make HTTP requests directly, this script:
-- 1. Lists routes missing geometry
-- 2. Generates the OSRM URLs for manual quick-fill
-- 3. Provides a SQL template for each route
--
-- For production: use the backfill-route edge function instead.
-- See supabase/functions/backfill-route/

-- Check which routes need backfill
SELECT
  id,
  title,
  start_location,
  end_location,
  format(
    'https://router.project-osrm.org/route/v1/driving/%s,%s;%s,%s?overview=full&geometries=geojson',
    start_lng, start_lat, end_lng, end_lat
  ) AS osrm_url
FROM public.routes
WHERE geometry IS NULL
  AND start_lat IS NOT NULL
  AND start_lng IS NOT NULL
  AND end_lat IS NOT NULL
  AND end_lng IS NOT NULL;

-- Example UPDATE after fetching geometry from OSRM URL:
-- UPDATE public.routes
-- SET geometry = '[[lng,lat],[lng,lat],...]'
-- WHERE id = 'route-uuid-here';
