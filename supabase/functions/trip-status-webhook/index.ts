import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface TripWebhookPayload {
  tripId: string;
  status: 'arrive' | 'start' | 'complete' | 'cancel' | 'mark_absent';
  lat?: number;
  lng?: number;
  driverToken: string; // simple shared secret
}

/**
 * External webhook for driver app / third-party tracking.
 * Validates a shared secret, then calls the SQL RPC which enforces
 * FSM transitions (trip_state_machine) via the `update_trip_status` function.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: TripWebhookPayload = await req.json();
    const { tripId, status, lat, lng } = payload;

    const expected = Deno.env.get('DRIVER_WEBHOOK_SECRET');
    const clientSecret = req.headers.get('x-driver-secret');

    if (!expected || expected !== clientSecret) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!tripId || !status) {
      return new Response(JSON.stringify({ error: 'tripId, status required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    const { data, error } = await supabase.rpc('update_trip_status', {
      p_trip_id: tripId,
      p_new_status: status,
      p_lat: lat ?? null,
      p_lng: lng ?? null,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ success: true, trip: data }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Trip webhook error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
