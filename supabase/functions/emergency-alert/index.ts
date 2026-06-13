import { createAdminClient } from '../_shared/supabase.ts';
import { getCorsHeaders } from '../_shared/cors.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface EmergencyPayload {
  studentId: string;
  routeId: string;
  tripId: string;
  lat: number;
  lng: number;
  description: string;
}

/**
 * Triggered when a student submits an emergency report.
 * 1) Verifies student's authentication JWT
 * 2) Validates the trip belongs to the student and is active
 * 3) Validates coordinate range and rate-limits
 * 4) Creates the report row
 * 5) Notifies all admins via push notification (FCM)
 */
Deno.serve(async (req) => {
  const corsHeaders = getCorsHeaders(req.headers.get('Origin'));

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  // Only accept POST requests
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

    const payload: EmergencyPayload = await req.json();
    const { studentId, routeId, tripId, lat, lng, description } = payload;

    if (!studentId || !routeId || !tripId) {
      return new Response(JSON.stringify({ error: 'studentId, routeId, tripId required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Authenticate the user token using Supabase
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!;
    const userClient = createClient(supabaseUrl, supabaseAnonKey, {
      auth: { autoRefreshToken: false, persistSession: false },
      global: { headers: { Authorization: authHeader } }
    });

    const { data: { user }, error: authError } = await userClient.auth.getUser();
    if (authError || !user) {
      return new Response(JSON.stringify({ error: 'unauthorized: invalid token' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify studentId in the body matches the authenticated user ID
    if (studentId !== user.id) {
      return new Response(JSON.stringify({ error: 'forbidden: ID mismatch' }), {
        status: 403,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // NEW: Validate coordinate range
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
      return new Response(JSON.stringify({ error: 'invalid coordinates' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    // NEW: Verify trip exists and matches routeId
    const { data: trip } = await supabase
      .from('trips')
      .select('id, route_id, status')
      .eq('id', tripId)
      .single();

    if (!trip || trip.route_id !== routeId) {
      return new Response(
        JSON.stringify({ error: 'forbidden: trip not found or route mismatch' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // NEW: Verify the student has an active subscription for this route
    const { data: sub } = await supabase
      .from('subscriptions')
      .select('id')
      .eq('student_id', studentId)
      .eq('route_id', routeId)
      .eq('status', 'active')
      .maybeSingle();

    if (!sub) {
      return new Response(
        JSON.stringify({ error: 'forbidden: no active subscription for this route' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // NEW: Rate limit: max 1 emergency report per 5 minutes per user
    const { count } = await supabase
      .from('emergency_reports')
      .select('id', { count: 'exact' })
      .eq('user_id', studentId)
      .gte('created_at', new Date(Date.now() - 5 * 60 * 1000).toISOString());

    if (count && count >= 1) {
      return new Response(
        JSON.stringify({ error: 'rate limited: one emergency report per 5 minutes allowed' }),
        { status: 429, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Create emergency report
    const { data: report, error: insertError } = await supabase
      .from('emergency_reports')
      .insert({
        user_id: studentId,
        trip_id: tripId,
        latitude: lat,
        longitude: lng,
        message: description || '',
      })
      .select('id')
      .single();

    if (insertError) throw insertError;

    // Notify admins
    const adminQuery = await supabase.from('profiles').select('id').eq('role', 'admin');
    const admins = (adminQuery.data ?? []).filter((a: { id: string }) => a.id);

    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (supabaseUrl && serviceRoleKey && admins.length > 0) {
      const sendNotificationUrl = `${supabaseUrl}/functions/v1/send-push-notification`;
      for (const admin of admins) {
        try {
          await fetch(sendNotificationUrl, {
            method: 'POST',
            headers: {
              'Authorization': `Bearer ${serviceRoleKey}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              userId: admin.id,
              title: 'تنبيه حالة طوارئ! / Emergency Alert!',
              body: description || 'أبلغ أحد الطلاب عن حالة طوارئ. / A student has reported an emergency.',
              data: {
                studentId: studentId,
                routeId: routeId,
                tripId: tripId,
                lat: String(lat),
                lng: String(lng),
              },
            }),
          });
        } catch (err) {
          console.error(`Error notifying admin ${admin.id}:`, err);
        }
      }
    }

    return new Response(JSON.stringify({
      reportId: report?.id,
      notifiedAdmins: admins.length,
    }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Emergency alert error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

