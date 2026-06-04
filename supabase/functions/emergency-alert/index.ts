import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

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
 * 1) Creates the report row
 * 2) Notifies all admins via push notification (FCM)
 * 3) Returns the report ID + notified admin count
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: EmergencyPayload = await req.json();
    const { studentId, routeId, tripId, lat, lng, description } = payload;

    if (!studentId || !routeId || !tripId) {
      return new Response(JSON.stringify({ error: 'studentId, routeId, tripId required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

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
    const admins = adminQuery.data ?? [];

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
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
              title: 'Emergency Alert!',
              body: description || 'A student has reported an emergency.',
              data: {
                studentId,
                routeId,
                tripId,
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
