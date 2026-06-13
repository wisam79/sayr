import { createAdminClient } from '../_shared/supabase.ts';
import { getCorsHeaders } from '../_shared/cors.ts';

interface TripWebhookPayload {
  tripId: string;
  status: 'arrive' | 'start' | 'complete' | 'cancel' | 'mark_absent';
  lat?: number;
  lng?: number;
  driverId: string; // UUID of the driver assigned to this trip (REQUIRED)
}

/**
 * External webhook for driver app / third-party tracking.
 * Validates a shared secret AND verifies the driver actually owns this trip,
 * then calls the SQL RPC which enforces FSM transitions.
 */
Deno.serve(async (req) => {
  const corsHeaders = getCorsHeaders(req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: TripWebhookPayload = await req.json();
    const { tripId, status, lat, lng, driverId } = payload;

    const expected = Deno.env.get('DRIVER_WEBHOOK_SECRET');
    const clientSecret = req.headers.get('x-driver-secret');

    if (!expected || !clientSecret) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
    const encoder = new TextEncoder();
    const a = encoder.encode(expected);
    const b = encoder.encode(clientSecret);
    if (a.byteLength !== b.byteLength || !crypto.subtle.timingSafeEqual(a, b)) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!tripId || !status || !driverId) {
      return new Response(JSON.stringify({ error: 'tripId, status, driverId required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    // CRITICAL: Verify the driver actually owns this trip before touching it.
    // Prevents a single leaked webhook secret from controlling ALL trips.
    const { data: trip, error: tripError } = await supabase
      .from('trips')
      .select('id, driver_id')
      .eq('id', tripId)
      .single();

    if (tripError || !trip) {
      return new Response(JSON.stringify({ error: 'trip not found' }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (trip.driver_id !== driverId) {
      return new Response(JSON.stringify({ error: 'forbidden: driver mismatch' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const statusMap: Record<string, string> = {
      'arrive': 'driver_waiting',
      'start': 'in_transit',
      'complete': 'completed',
      'cancel': 'cancelled',
      'mark_absent': 'absent'
    };

    const mappedStatus = statusMap[status] || status;

    const { data, error } = await supabase.rpc('update_trip_status', {
      p_trip_id: tripId,
      p_new_status: mappedStatus,
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
