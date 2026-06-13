import { createAdminClient } from '../_shared/supabase.ts';
import { getCorsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface LocationUpdate {
  tripId: string;
  lat: number;
  lng: number;
  ts: string; // ISO timestamp
}

/**
 * Accept bulk location updates from a driver's offline queue,
 * then pass to the SQL RPC for efficient batch insert/update.
 *
 * Security: Authenticated drivers only. The SQL function per-element
 * check (update_trip_location) enforces that the trip belongs to the
 * calling driver and is in an active state.
 */
Deno.serve(async (req) => {
  const corsHeaders = getCorsHeaders(req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'unauthorized: missing header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const body = await req.json();
    const locations: LocationUpdate[] = body?.locations ?? [];

    if (!Array.isArray(locations) || locations.length === 0) {
      return new Response(JSON.stringify({ error: 'locations array required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Authenticate using the driver's own JWT instead of service_role.
    // This ensures the per-element SQL check (d.user_id = auth.uid()) works.
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } },
    });

    // Verify the user is authenticated
    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'unauthorized: invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Map to the format expected by the SQL bulk RPC
    const locationsPayload = locations.map((l: LocationUpdate) => ({
      trip_id: l.tripId,
      lat: l.lat,
      lng: l.lng,
      ts: l.ts,
    }));

    const { data, error } = await userClient.rpc('bulk_update_trip_locations', {
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
