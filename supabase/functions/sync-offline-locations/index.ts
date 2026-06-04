import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface LocationUpdate {
  tripId: string;
  lat: number;
  lng: number;
  ts: string; // ISO timestamp
}

/**
 * Accept bulk location updates from a driver's offline queue,
 * then pass to the SQL RPC for efficient batch insert/update.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const body = await req.json();
    const locations: LocationUpdate[] = body?.locations ?? [];

    if (!Array.isArray(locations) || locations.length === 0) {
      return new Response(JSON.stringify({ error: 'locations array required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    // Map to the format expected by the SQL bulk RPC
    const locationsPayload = locations.map((l: LocationUpdate) => ({
      trip_id: l.tripId,
      lat: l.lat,
      lng: l.lng,
      ts: l.ts,
    }));

    const { data, error } = await supabase.rpc('bulk_update_trip_locations', {
      p_locations: locationsPayload,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ synced: locations.length, data }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Offline sync error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
