-- Migration: 20260603000001_extensions.sql
-- Description: Enable required PostgreSQL extensions

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pgcrypto" WITH SCHEMA extensions;
CREATE EXTENSION IF NOT EXISTS "pg_cron" WITH SCHEMA extensions;

-- Grant usage on extensions schema
GRANT USAGE ON SCHEMA extensions TO authenticated, anon;
