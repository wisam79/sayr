/**
 * CORS header helper for Supabase Edge Functions.
 *
 * Validates the incoming request `Origin` against the comma-separated
 * `ALLOWED_ORIGIN` env var. Falls back to the first allowed origin
 * when the request origin is missing or not in the allow-list.
 */

const allowedOrigins: string[] = (Deno.env.get('ALLOWED_ORIGIN') ?? '')
  .split(',')
  .map((o) => o.trim())
  .filter(Boolean);

/**
 * Build CORS headers that reflect the request origin when it matches
 * the allow-list. If the origin is not recognised the first allowed
 * origin is returned instead (safe — browsers will block the request).
 */
export function getCorsHeaders(requestOrigin?: string | null): Record<string, string> {
  const origin =
    requestOrigin && allowedOrigins.includes(requestOrigin)
      ? requestOrigin
      : allowedOrigins[0] ?? '';

  return {
    'Access-Control-Allow-Origin': origin,
    'Access-Control-Allow-Headers':
      'authorization, x-client-info, apikey, content-type, x-driver-secret',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
  };
}

/**
 * @deprecated Use `getCorsHeaders(req.headers.get('Origin'))` instead.
 * Kept for backward-compatibility during migration.
 */
export const corsHeaders = getCorsHeaders();
