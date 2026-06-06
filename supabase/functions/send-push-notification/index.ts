import { createAdminClient } from '../_shared/supabase.ts';
import { corsHeaders } from '../_shared/cors.ts';

interface NotificationPayload {
  userId: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

/**
 * Send FCM push notification via Firebase Cloud Messaging HTTP v1 API.
 * Triggered by: Database webhook (when row inserted into notifications table)
 *
 * Security:
 * - Only callable with service_role key (database webhooks use this)
 * - Never leaks FCM tokens in response
 * - Validates all required fields
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
    // Verify the request is authenticated with service_role
    const authHeader = req.headers.get('Authorization');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!authHeader || !serviceRoleKey || authHeader !== `Bearer ${serviceRoleKey}`) {
      return new Response(JSON.stringify({ error: 'unauthorized' }), {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    const { userId, title, body, data }: NotificationPayload = await req.json();

    if (!userId || !title || !body) {
      return new Response(
        JSON.stringify({ error: 'userId, title, body required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    const supabase = createAdminClient();
    const firebaseProjectId = Deno.env.get('FIREBASE_PROJECT_ID');
    const firebaseServiceAccount = Deno.env.get('FIREBASE_SERVICE_ACCOUNT');

    // Get user's FCM tokens from push_tokens table (supports multiple active devices)
    const { data: tokens, error: tokensError } = await supabase
      .from('push_tokens')
      .select('token')
      .eq('user_id', userId)
      .eq('is_active', true);

    if (tokensError || !tokens || tokens.length === 0) {
      return new Response(
        JSON.stringify({ skipped: true, reason: 'no active fcm token' }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    if (!firebaseProjectId || !firebaseServiceAccount) {
      console.error('Firebase credentials not configured');
      return new Response(
        JSON.stringify({ error: 'push notification service misconfigured' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        },
      );
    }

    // Get OAuth2 access token for Firebase Admin
    const serviceAccount = JSON.parse(firebaseServiceAccount);
    const accessToken = await getFirebaseAccessToken(serviceAccount);

    let sentCount = 0;
    for (const item of tokens) {
      try {
        // Send FCM message via HTTP v1 API
        const fcmResponse = await fetch(
          `https://fcm.googleapis.com/v1/projects/${firebaseProjectId}/messages:send`,
          {
            method: 'POST',
            headers: {
              Authorization: `Bearer ${accessToken}`,
              'Content-Type': 'application/json',
            },
            body: JSON.stringify({
              message: {
                token: item.token,
                notification: { title, body },
                data: data ?? {},
                android: { priority: 'high' },
              },
            }),
          },
        );

        if (fcmResponse.ok) {
          sentCount++;
        } else {
          const fcmError = await fcmResponse.text();
          console.error(`FCM send failed for token ${item.token}: ${fcmResponse.status} ${fcmError}`);

          // If token is invalid (404 Not Found or 400 Bad Request), mark it as inactive
          if (fcmResponse.status === 404 || fcmResponse.status === 400) {
            await supabase
              .from('push_tokens')
              .update({ is_active: false })
              .eq('token', item.token);
          }
        }
      } catch (err) {
        console.error(`Error sending to token ${item.token}:`, err);
      }
    }

    if (sentCount === 0) {
      return new Response(JSON.stringify({ sent: false, error: 'fcm send failed for all tokens' }), {
        status: 502,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      });
    }

    // Never return tokens in response
    return new Response(JSON.stringify({ sent: true, sentCount }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : 'unknown error';
    console.error('Push notification error:', message);
    return new Response(JSON.stringify({ error: message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }
});

/**
 * Get a Firebase OAuth2 access token from a service account.
 */
async function getFirebaseAccessToken(
  serviceAccount: { client_email: string; private_key: string },
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const expiry = now + 3600;

  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: expiry,
  };

  const encoder = new TextEncoder();
  const headerBase64 = btoa(JSON.stringify(header));
  const payloadBase64 = btoa(JSON.stringify(payload));
  const signingInput = `${headerBase64}.${payloadBase64}`;

  const key = await crypto.subtle.importKey(
    'pkcs8',
    pemToDer(serviceAccount.private_key),
    { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    key,
    encoder.encode(signingInput),
  );

  const signatureBase64 = btoa(
    String.fromCharCode(...new Uint8Array(signature)),
  );

  const jwt = `${signingInput}.${signatureBase64}`;

  const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const { access_token } = await tokenResponse.json();
  return access_token;
}

function pemToDer(pem: string): ArrayBuffer {
  const base64 = pem
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '');
  const binaryString = atob(base64);
  const bytes = new Uint8Array(binaryString.length);
  for (let i = 0; i < binaryString.length; i++) {
    bytes[i] = binaryString.charCodeAt(i);
  }
  return bytes.buffer;
}
