# Sayr v3 Edge Functions

## Overview

6 Deno functions for the Sayr backend. All functions use `createAdminClient()` which requires `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` environment variables.

## Functions

1. **`create-route`** - Admin-only route creation. Validates admin JWT, calls OSRM once to calculate route geometry, stores the geometry with the route in DB.
2. **`send-push-notification`** - Sends FCM push notification to a user's device(s). Triggered by DB webhook on `notifications` table insert.
3. **`process-payment`** - Receives Zain Cash callback/webhook. Calls the atomic SQL function `complete_payment_and_activate_subscription` on success.
4. **`sync-offline-locations`** - Accepts bulk location updates from driver offline queue. Calls `bulk_update_trip_locations` RPC.
5. **`emergency-alert`** - Triggered when a student files an emergency report. Creates the row + notifies all admins.
6. **`generate-driver-report`** - Admin-only (or cron) function. Calls `get_driver_stats` SQL RPC for earnings/trip summary.
7. **`trip-status-webhook`** - External webhook for driver app. Validates shared secret `DRIVER_WEBHOOK_SECRET`, then calls `update_trip_status` FSM-validated RPC.
8. **`keep-osrm-alive`** - Keep-alive ping function for private Hugging Face OSRM space. Triggered by pg_cron every 12 hours.

## Deployment

```bash
# Link to your project (run once)
supabase link --project-ref cdydfiiufaebljfduybx

# Push all migrations
supabase db push

# Deploy all functions
supabase functions deploy --all

# Or deploy individually
supabase functions deploy create-route
supabase functions deploy keep-osrm-alive
supabase functions deploy send-push-notification
supabase functions deploy process-payment
supabase functions deploy sync-offline-locations
supabase functions deploy emergency-alert
supabase functions deploy generate-driver-report
supabase functions deploy trip-status-webhook
```

## Environment Variables

Set in Supabase Dashboard > Edge Functions > Secrets:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `DRIVER_WEBHOOK_SECRET` (for trip-status-webhook)
- `GOOGLE_CLIENT_ID` (for auth, if not already set)
- `GOOGLE_CLIENT_SECRET` (for auth)
