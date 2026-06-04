import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface ReportParams {
  driverId: string;
  startDate?: string; // ISO yyyy-mm-dd
  endDate?: string;
}

/**
 * Admin-only cron function (or callable) to generate a driver's
 * trip + earnings + payout summary.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const { driverId, startDate, endDate }: ReportParams = await req.json();

    if (!driverId) {
      return new Response(JSON.stringify({ error: 'driverId required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    // Rely on the SQL view/function for aggregation (does not exist yet in schema)
    const { data, error } = await supabase.rpc('get_driver_stats', {
      p_driver_id: driverId,
      p_start_date: startDate ?? null,
      p_end_date: endDate ?? null,
    });

    if (error) throw error;

    return new Response(JSON.stringify({ driverId, stats: data }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Driver report error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
