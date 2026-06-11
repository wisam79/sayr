-- Migration: 20260610000002_add_route_geometry.sql
-- Description: Add geometry column for storing route path
-- This allows storing OSRM-calculated route geometry once per route
-- instead of calling OSRM for every user on every view.

ALTER TABLE public.routes 
ADD COLUMN geometry TEXT;

CREATE INDEX idx_routes_geometry ON public.routes(geometry) WHERE geometry IS NOT NULL;

COMMENT ON COLUMN public.routes.geometry IS 
'JSON string of route coordinates [[lng, lat], [lng, lat], ...] from OSRM. '
'Calculated once when route is created, reused by all users.';