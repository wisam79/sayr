import { createAdminClient } from '../_shared/supabase.ts';
import { getCorsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface CreateRoutePayload {
  driverId: string;
  title: string;
  startLocation: string;
  endLocation: string;
  startLat: number;
  startLng: number;
  endLat: number;
  endLng: number;
  price: number;
  capacity: number;
  institutionId?: string;
  departureTime?: string;
  returnTime?: string;
  daysOfWeek?: string[];
}

/**
 * Admin-only function to create a new route with OSRM-calculated geometry.
 *
 * Flow:
 * 1. Auth check (admin only)
 * 2. Call OSRM once to calculate route geometry
 * 3. Insert route + geometry into DB
 *
 * OSRM is called only once per route creation, not per user view.
 */
Deno.serve(async (req) => {
  const corsHeaders = getCorsHeaders(req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  if (req.method !== 'POST') {
    return new Response(JSON.stringify({ error: 'method not allowed' }), {
      status: 405,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  try {
    // Verify admin JWT
    const authHeader = req.headers.get('Authorization');
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'unauthorized: missing header' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } },
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'unauthorized: invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const role = user.app_metadata?.role;
    if (role !== 'admin') {
      return new Response(JSON.stringify({ error: 'forbidden: admin only' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Parse and validate payload
    const payload: CreateRoutePayload = await req.json();
    const {
      driverId, title, startLocation, endLocation,
      startLat, startLng, endLat, endLng,
      price, capacity,
    } = payload;

    if (!driverId || !title || !startLocation || !endLocation) {
      return new Response(JSON.stringify({ error: 'missing required fields: driverId, title, startLocation, endLocation' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!price || price <= 0) {
      return new Response(JSON.stringify({ error: 'invalid price' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!capacity || capacity <= 0) {
      return new Response(JSON.stringify({ error: 'invalid capacity' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (startLat == null || startLng == null || endLat == null || endLng == null) {
      return new Response(JSON.stringify({ error: 'start/end coordinates required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Calculate route geometry via OSRM (once per route).
    // HF_TOKEN authenticates against a private Hugging Face Space —
    // the token never leaves this Edge Function and is never sent to clients.
    let geometry: string | null = null;
    try {
      const baseOsrmUrl = Deno.env.get('OSRM_URL') || 'https://wisam99-sayrosrm.hf.space/route/v1/driving';
      const osrmUrl = `${baseOsrmUrl}/${startLng},${startLat};${endLng},${endLat}?overview=full&geometries=geojson`;

      const osrmHeaders: Record<string, string> = { 'Accept': 'application/json' };
      const hfToken = Deno.env.get('HF_TOKEN');
      if (hfToken) {
        osrmHeaders['Authorization'] = `Bearer ${hfToken}`;
      }

      const osrmResponse = await fetch(osrmUrl, { headers: osrmHeaders });

      if (osrmResponse.ok) {
        const osrmData = await osrmResponse.json();
        const coordinates = osrmData?.routes?.[0]?.geometry?.coordinates;
        if (coordinates && Array.isArray(coordinates) && coordinates.length > 0) {
          geometry = JSON.stringify(coordinates);
        }
      } else {
        console.warn(`OSRM returned ${osrmResponse.status}, saving route without geometry`);
      }
    } catch (osrmError) {
      console.warn('OSRM request failed, saving route without geometry:', osrmError);
    }

    // Insert route with geometry into DB
    const supabase = createAdminClient();
    const { data, error } = await supabase
      .from('routes')
      .insert({
        driver_id: driverId,
        title,
        start_location: startLocation,
        end_location: endLocation,
        start_lat: startLat,
        start_lng: startLng,
        end_lat: endLat,
        end_lng: endLng,
        price,
        capacity,
        available_seats: capacity,
        institution_id: payload.institutionId ?? null,
        departure_time: payload.departureTime ?? null,
        return_time: payload.returnTime ?? null,
        days_of_week: payload.daysOfWeek ?? ['sun', 'mon', 'tue', 'wed', 'thu'],
        is_active: true,
        geometry,
      })
      .select()
      .single();

    if (error) throw error;

    console.log(`Route created: ${data.id} with geometry=${geometry ? '✅' : '❌'}`);

    return new Response(JSON.stringify({ success: true, route: data }), {
      status: 201,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Create route error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
