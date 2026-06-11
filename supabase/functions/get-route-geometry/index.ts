import { corsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface GetRouteGeometryPayload {
  startLng: number;
  startLat: number;
  endLng: number;
  endLat: number;
}

/**
 * Proxy function that calls OSRM (hosted on Hugging Face) on behalf of the client.
 *
 * The Flutter app never knows the HF Space URL or HF_TOKEN.
 * Authentication: user JWT (any authenticated user).
 */
Deno.serve(async (req) => {
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

    const payload: GetRouteGeometryPayload = await req.json();
    const { startLng, startLat, endLng, endLat } = payload;

    if (startLng == null || startLat == null || endLng == null || endLat == null) {
      return new Response(JSON.stringify({ error: 'start/end coordinates required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const baseOsrmUrl = Deno.env.get('OSRM_URL') ||
      'https://wisam99-sayrosrm.hf.space/route/v1/driving';
    const osrmUrl =
      `${baseOsrmUrl}/${startLng},${startLat};${endLng},${endLat}?overview=full&geometries=geojson`;

    const osrmHeaders: Record<string, string> = { 'Accept': 'application/json' };
    const hfToken = Deno.env.get('HF_TOKEN');
    if (hfToken) {
      osrmHeaders['Authorization'] = `Bearer ${hfToken}`;
    }

    const osrmResponse = await fetch(osrmUrl, { headers: osrmHeaders });

    if (!osrmResponse.ok) {
      console.error(`OSRM returned ${osrmResponse.status}`);
      return new Response(JSON.stringify({ error: 'routing failed', coordinates: [] }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const osrmData = await osrmResponse.json();
    const coordinates = osrmData?.routes?.[0]?.geometry?.coordinates;

    if (!coordinates || !Array.isArray(coordinates) || coordinates.length === 0) {
      return new Response(JSON.stringify({ error: 'no route found', coordinates: [] }), {
        status: 404,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    return new Response(JSON.stringify({ coordinates }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('get-route-geometry error:', message);
    return new Response(JSON.stringify({ error: message, coordinates: [] }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
