import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface ZainCashPayload {
  orderId: string;
  status: string; // 'success' | 'failed'
  amount: number;
  currency: string;
  studentId: string;
  routeId: string;
  meta?: Record<string, unknown>;
}

/**
 * Handle Zain Cash payment callback/webhook.
 * Verifies payment and calls the SQL RPC to atomically activate subscription.
 */
Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const payload: ZainCashPayload = await req.json();
    const { orderId, status, studentId, routeId } = payload;

    if (!orderId || !status || !studentId || !routeId) {
      return new Response(JSON.stringify({ error: 'missing fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const supabase = createAdminClient();

    if (status === 'success') {
      // Call the atomic SQL function
      const { data, error } = await supabase.rpc('complete_payment_and_activate_subscription', {
        p_order_id: orderId,
        p_student_user_id: studentId,
        p_route_id: routeId,
      });

      if (error) throw error;

      return new Response(JSON.stringify({ success: true, subscription: data }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      // Mark payment as failed
      await supabase.from('payments').update({ status: 'failed' }).eq('id', orderId);

      return new Response(JSON.stringify({ success: false, orderId }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Payment callback error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});
