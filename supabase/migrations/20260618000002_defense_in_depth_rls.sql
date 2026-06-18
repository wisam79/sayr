-- Migration: 20260618000002_defense_in_depth_rls.sql
-- Description: Apply defense-in-depth hardening flagged in the engineering review.
--
--   Fix #1: FORCE ROW LEVEL SECURITY on tables holding sensitive data so that
--          even the table owner (e.g. a migration role) cannot bypass RLS.
--          With RLS enabled but not forced, the owner reads/writes every row.
--   Fix #2: REVOKE EXECUTE FROM PUBLIC on every non-trigger helper/RPC so they
--          cannot be invoked by anonymous clients. Explicit GRANTs to
--          `authenticated` / `service_role` remain in place from prior
--          migrations; this only removes the implicit PUBLIC default.
--   Fix #3: REVOKE the few remaining PUBLIC grants on internal trigger/handle
--          helpers. They are invoked by the system on row changes, never by
--          clients, so they must not be directly callable.
--
-- Idempotency: every statement uses IF EXISTS guards so re-running the
-- migration (or partially applying it) never errors.

-- ============================================================
-- Fix #1: FORCE Row Level Security on sensitive tables
-- ============================================================
-- RLS is already ENABLED on these tables; FORCE additionally blocks the
-- table owner from bypassing policies. This is the Supabase-recommended
-- hardening for tables with PII, payments, or licensing data.

ALTER TABLE IF EXISTS public.profiles FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.drivers_data FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.licenses FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.license_batches FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.subscriptions FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.payments FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.driver_payouts FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.trips FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.boarding_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.boardings FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.messages FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.conversations FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.emergency_reports FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.support_requests FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.ratings FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.push_tokens FORCE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS public.audit_logs FORCE ROW LEVEL SECURITY;

-- NOTE: app_config, cron_health, rate_limits, notification_log intentionally
-- NOT forced here: they are read via SECURITY DEFINER RPCs (get_app_config,
-- check_rate_limit) that return curated rows, and forcing RLS on them would
-- require granting the owner role explicitly. They remain RLS-enabled (default
-- deny) which is the correct posture for write-internal tables.

-- ============================================================
-- Fix #2: REVOKE EXECUTE FROM PUBLIC on client-facing RPCs that were
--         missing the explicit revoke (cancel_subscription, register_push_token,
--         get_unread_count, get_my_role, create_trip, update_trip_*,
--         bulk_update_trip_locations). Explicit GRANTs to `authenticated`
--         from earlier migrations are untouched.
-- ============================================================

REVOKE EXECUTE ON FUNCTION public.cancel_subscription(UUID) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.register_push_token(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_unread_count() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.get_my_role() FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.create_trip(UUID, TIMESTAMPTZ) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_trip_location(UUID, NUMERIC, NUMERIC) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.update_trip_status(UUID, TEXT, NUMERIC, NUMERIC) FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.bulk_update_trip_locations(JSONB) FROM PUBLIC, anon;

-- ============================================================
-- Fix #3: Internal trigger / helper functions must never be callable by
--         clients. Revoke from PUBLIC, anon, and authenticated. These are
--         invoked by the database itself (triggers / cron / service_role).
-- ============================================================

-- Authentication / role-sync helpers (run via triggers on auth events)
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_profile_role_to_auth() FROM PUBLIC, anon, authenticated;

-- Trigger helpers that enforce row-level business rules
REVOKE ALL ON FUNCTION public.enforce_message_immutability() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.enforce_emergency_report_update_rules() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.enforce_support_request_rules() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.licenses_guard_reactivation() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.routes_guard_business_columns() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_message() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.trigger_send_push() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.manage_drivers_view() FROM PUBLIC, anon, authenticated;

-- Role-check helpers used inside RLS policies (SECURITY DEFINER, invoked by
-- the planner, not by clients)
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.is_driver() FROM PUBLIC, anon, authenticated;

-- Scheduled maintenance helpers (invoked by cron / service_role only)
REVOKE ALL ON FUNCTION public.expire_subscriptions_and_return_seats() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.cleanup_expired_rate_limits() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.reclaim_pending_reservations() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.complete_payment_and_activate_subscription(UUID, UUID, UUID, UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.update_payout_status(UUID, TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.create_license_batch(UUID, TEXT, INTEGER, NUMERIC, INTEGER) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.check_rate_limit(UUID, TEXT, INTEGER, INTEGER) FROM PUBLIC, anon, authenticated;

-- Driver-rating sync (trigger-driven, not client-callable)
REVOKE ALL ON FUNCTION public.sync_driver_rating() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_driver_role_promotion() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.sync_driver_role_demotion() FROM PUBLIC, anon, authenticated;

-- Explicitly KEEP these callable by anon (intentional public surface):
--   public.ping()              — health probe
--   public.get_app_config()    — public app configuration read
-- No revoke is applied to them.
