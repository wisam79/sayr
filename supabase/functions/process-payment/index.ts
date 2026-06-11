import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface ZainCashPayload {
  orderId: string;
  status: string; // 'success' | 'failed'
  amount: number;
  currency: string;
  studentId: string;
  routeId: string;
  signature?: string;
  meta?: Record<string, unknown>;
}

/**
 * Verify Zain Cash webhook signature using HMAC-SHA256.
 * The signature is computed over the raw body with the merchant secret.
 */
async function verifySignature(
  body: string,
  signature: string,
  secret: string,
): Promise<boolean> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const signatureBuffer = await crypto.subtle.sign('HMAC', key, encoder.encode(body));
  const expectedSignature = Array.from(new Uint8Array(signatureBuffer))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
  return expectedSignature === signature;
}

/**
 * Handle Zain Cash payment callback/webhook.
 * Verifies payment and calls the SQL RPC to atomically activate subscription.
 *
 * Security:
 * - HMAC-SHA256 signature verification from Zain Cash
 * - Idempotency check (prevents double-processing)
 * - Input validation on all required fields
 */
Deno.serve(async (req) => {
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
    const rawBody = await req.text();
    const payload: ZainCashPayload = JSON.parse(rawBody);
    const { orderId, status, studentId, routeId, signature } = payload;

    if (!orderId || !status || !studentId || !routeId) {
      return new Response(JSON.stringify({ error: 'missing fields' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Verify HMAC signature from Zain Cash
    const merchantSecret = Deno.env.get('ZAINCASH_SECRET');
    if (!merchantSecret) {
      console.error('ZAINCASH_SECRET not configured');
      return new Response(JSON.stringify({ error: 'server misconfiguration' }), {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (!signature) {
      return new Response(JSON.stringify({ error: 'missing signature' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Strip signature and meta from object to prevent circular dependency in HMAC signature calculation
    const signedData = {
      orderId: payload.orderId,
      status: payload.status,
      amount: payload.amount,
      currency: payload.currency,
      studentId: payload.studentId,
      routeId: payload.routeId,
      ...(payload.meta ? { meta: payload.meta } : {})
    };
    const cleanBody = JSON.stringify(signedData);

    const isValid = await verifySignature(cleanBody, signature, merchantSecret);
    if (!isValid) {
      console.error(`Invalid signature for order ${orderId}`);
      return new Response(JSON.stringify({ error: 'invalid signature' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }


    const supabase = createAdminClient();

    // Idempotency check: skip if payment already processed
    const { data: existingPayment, error: fetchError } = await supabase
      .from('payments')
      .select('status, license_id, subscription_id, user_id, amount')
      .eq('id', orderId)
      .single();

    if (fetchError || !existingPayment) {
      return new Response(
        JSON.stringify({ error: `Payment record not found for orderId: ${orderId}` }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    if (Number(payload.amount) !== Number(existingPayment.amount)) {
      console.error(`Payment amount mismatch for order ${orderId}: expected ${existingPayment.amount}, got ${payload.amount}`);
      return new Response(JSON.stringify({ error: 'amount mismatch' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    if (existingPayment.status !== 'pending') {
      return new Response(
        JSON.stringify({ success: true, message: 'already processed' }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    if (status === 'success') {
      // Call the atomic SQL function with correct 4 UUID parameters (handles payment status update internally)
      const { data, error } = await supabase.rpc(
        'complete_payment_and_activate_subscription',
        {
          p_payment_id: orderId,
          p_user_id: existingPayment.user_id,
          p_license_id: existingPayment.license_id,
          p_subscription_id: existingPayment.subscription_id,
        },
      );

      if (error) throw error;

      return new Response(JSON.stringify({ success: true, subscription: data }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    } else {
      // Mark payment as failed
      await supabase
        .from('payments')
        .update({ status: 'failed', updated_at: new Date().toISOString() })
        .eq('id', orderId);

      // Cancel the subscription to release the seat immediately
      if (existingPayment.subscription_id) {
        await supabase.rpc('cancel_subscription', {
          p_subscription_id: existingPayment.subscription_id,
        });
      }

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
