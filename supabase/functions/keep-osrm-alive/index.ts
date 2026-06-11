import { corsHeaders } from '../_shared/cors.ts';

/**
 * Keep-alive ping function for Hugging Face OSRM Space.
 *
 * Can be triggered periodically via pg_cron to ensure the private OSRM Space
 * does not enter sleep mode due to inactivity.
 * Authorization: SUPABASE_SERVICE_ROLE_KEY.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // 1. Verify service_role key to prevent public abuse
    const authHeader = req.headers.get('Authorization');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!authHeader || !serviceRoleKey || authHeader !== `Bearer ${serviceRoleKey}`) {
      console.warn('Unauthorized keep-alive attempt rejected.');
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // 2. Resolve Hugging Face Space OSRM URL and Token
    const baseOsrmUrl = Deno.env.get('OSRM_URL') ||
      'https://wisam99-sayrosrm.hf.space/route/v1/driving';
    const hfToken = Deno.env.get('HF_TOKEN');

    // Make a simple ping request with minimal output using Baghdad Jadriya coordinates
    const pingUrl =
      `${baseOsrmUrl}/44.366,33.315;44.366,33.315?overview=false&geometries=geojson`;

    const headers: Record<string, string> = { 'Accept': 'application/json' };
    if (hfToken) {
      headers['Authorization'] = `Bearer ${hfToken}`;
    }

    console.log(`Sending keep-alive ping to: ${baseOsrmUrl}`);
    const response = await fetch(pingUrl, { headers });

    if (!response.ok) {
      throw new Error(`OSRM Space returned HTTP ${response.status}`);
    }

    const data = await response.json();
    console.log('OSRM Space keep-alive ping succeeded!');

    return new Response(JSON.stringify({ success: true, message: 'OSRM pinged successfully' }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('OSRM keep-alive failed:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
