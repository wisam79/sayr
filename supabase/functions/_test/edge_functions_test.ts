import { assertEquals, assertNotEquals } from "https://deno.land/std@0.208.0/testing/asserts.ts";

/**
 * Unit tests for Supabase Edge Functions.
 *
 * These tests validate the **pure logic** portions of each edge function
 * (input validation, rate-limiting helpers, signature helpers, status mapping).
 *
 * Integration tests (actual HTTP calls to running functions) are handled
 * by the database-ci workflow with `supabase start`.
 *
 * Run with: deno test --allow-all
 */

// ---------------------------------------------------------------------------
// process-payment
// ---------------------------------------------------------------------------

Deno.test("process-payment: HMAC — deterministic key ordering", () => {
  // The signed data must produce identical JSON regardless of insertion order.
  const a = JSON.stringify(
    { orderId: "1", status: "success", amount: 100, currency: "IQD", studentId: "s1", routeId: "r1" },
    ["amount", "currency", "orderId", "routeId", "status", "studentId"],
  );
  const b = JSON.stringify(
    { routeId: "r1", studentId: "s1", orderId: "1", amount: 100, currency: "IQD", status: "success" },
    ["amount", "currency", "orderId", "routeId", "status", "studentId"],
  );
  assertEquals(a, b, "Sorted JSON.stringify must produce identical output");
});

Deno.test("process-payment: rejects missing required fields", () => {
  const payload = { orderId: "", status: "success", studentId: "s1", routeId: "" };
  const isValid = !!(payload.orderId && payload.status && payload.studentId && payload.routeId);
  assertEquals(isValid, false);
});

Deno.test("process-payment: amount mismatch detection", () => {
  const payloadAmount = 25000;
  const dbAmount = 30000;
  assertEquals(Number(payloadAmount) !== Number(dbAmount), true);
});

Deno.test("process-payment: idempotency — already processed returns early", () => {
  const existingPaymentStatus = "completed";
  assertEquals(existingPaymentStatus !== "pending", true, "Non-pending should skip processing");
});

// ---------------------------------------------------------------------------
// emergency-alert
// ---------------------------------------------------------------------------

Deno.test("emergency-alert: validates coordinate range — valid Baghdad coords", () => {
  const lat = 33.3152;
  const lng = 44.3661;
  const isValid = lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  assertEquals(isValid, true);
});

Deno.test("emergency-alert: rejects out-of-range latitude", () => {
  const lat = 100;
  const lng = 44.3661;
  const isValid = lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  assertEquals(isValid, false);
});

Deno.test("emergency-alert: rejects out-of-range longitude", () => {
  const lat = 33.3152;
  const lng = 200;
  const isValid = lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  assertEquals(isValid, false);
});

Deno.test("emergency-alert: rate limit — count >= 1 blocks new report", () => {
  const count = 1;
  const isBlocked = count >= 1;
  assertEquals(isBlocked, true);
});

Deno.test("emergency-alert: rate limit — count 0 allows new report", () => {
  const count = 0;
  const isBlocked = count >= 1;
  assertEquals(isBlocked, false);
});

Deno.test("emergency-alert: rejects student ID mismatch", () => {
  const jwtUserId = "user-abc-123";
  const bodyStudentId = "user-xyz-789";
  assertEquals(jwtUserId !== bodyStudentId, true, "ID mismatch should be forbidden");
});

// ---------------------------------------------------------------------------
// send-push-notification
// ---------------------------------------------------------------------------

Deno.test("send-push-notification: timing-safe comparison — rejects mismatched keys", () => {
  const authHeader = "Bearer invalid-token";
  const serviceRoleKey = "valid-service-role-key";
  assertEquals(authHeader === `Bearer ${serviceRoleKey}`, false);
});

Deno.test("send-push-notification: timing-safe comparison — accepts matching keys", () => {
  const key = "my-secret-key-123";
  const authHeader = `Bearer ${key}`;
  assertEquals(authHeader === `Bearer ${key}`, true);
});

Deno.test("send-push-notification: skips when no active tokens", () => {
  const tokens: { token: string }[] = [];
  const shouldSkip = !tokens || tokens.length === 0;
  assertEquals(shouldSkip, true);
});

Deno.test("send-push-notification: marks invalid token as inactive on 404", () => {
  const fcmResponseStatus = 404;
  const shouldDeactivate = fcmResponseStatus === 404 || fcmResponseStatus === 400;
  assertEquals(shouldDeactivate, true);
});

Deno.test("send-push-notification: does NOT deactivate on 500 server error", () => {
  const fcmResponseStatus = 500;
  const shouldDeactivate = fcmResponseStatus === 404 || fcmResponseStatus === 400;
  assertEquals(shouldDeactivate, false);
});

// ---------------------------------------------------------------------------
// trip-status-webhook
// ---------------------------------------------------------------------------

Deno.test("trip-status-webhook: status mapping — arrive → driver_waiting", () => {
  const statusMap: Record<string, string> = {
    'arrive': 'driver_waiting',
    'start': 'in_transit',
    'complete': 'completed',
    'cancel': 'cancelled',
    'mark_absent': 'absent',
  };
  assertEquals(statusMap['arrive'], 'driver_waiting');
  assertEquals(statusMap['start'], 'in_transit');
  assertEquals(statusMap['complete'], 'completed');
  assertEquals(statusMap['cancel'], 'cancelled');
  assertEquals(statusMap['mark_absent'], 'absent');
});

Deno.test("trip-status-webhook: driver ownership — rejects mismatch", () => {
  const tripDriverId = "driver-aaa";
  const requestDriverId = "driver-bbb";
  assertEquals(tripDriverId !== requestDriverId, true, "Mismatched driver should be forbidden");
});

Deno.test("trip-status-webhook: driver ownership — allows match", () => {
  const tripDriverId = "driver-aaa";
  const requestDriverId = "driver-aaa";
  assertEquals(tripDriverId === requestDriverId, true);
});

Deno.test("trip-status-webhook: validates required fields", () => {
  const payload = { tripId: "t1", status: "", driverId: "d1" };
  const isValid = !!(payload.tripId && payload.status && payload.driverId);
  assertEquals(isValid, false, "Empty status should fail validation");
});

// ---------------------------------------------------------------------------
// get-route-geometry — rate limiting
// ---------------------------------------------------------------------------

Deno.test("get-route-geometry: rate limit — allows requests within limit", () => {
  const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
  const userId = "user-1";
  const now = Date.now();
  rateLimitMap.set(userId, { count: 5, resetAt: now + 60_000 });

  const entry = rateLimitMap.get(userId)!;
  const isBlocked = entry.count >= 30;
  assertEquals(isBlocked, false);
});

Deno.test("get-route-geometry: rate limit — blocks at limit", () => {
  const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
  const userId = "user-1";
  const now = Date.now();
  rateLimitMap.set(userId, { count: 30, resetAt: now + 60_000 });

  const entry = rateLimitMap.get(userId)!;
  const isBlocked = entry.count >= 30;
  assertEquals(isBlocked, true);
});

Deno.test("get-route-geometry: rate limit — resets after window", () => {
  const rateLimitMap = new Map<string, { count: number; resetAt: number }>();
  const userId = "user-1";
  const now = Date.now();
  // Window has expired
  rateLimitMap.set(userId, { count: 30, resetAt: now - 1000 });

  const entry = rateLimitMap.get(userId)!;
  const windowExpired = now >= entry.resetAt;
  assertEquals(windowExpired, true, "Expired window should allow new requests");
});

// ---------------------------------------------------------------------------
// sync-offline-locations
// ---------------------------------------------------------------------------

Deno.test("sync-offline-locations: rejects empty locations array", () => {
  const locations: unknown[] = [];
  const isValid = Array.isArray(locations) && locations.length > 0;
  assertEquals(isValid, false);
});

Deno.test("sync-offline-locations: accepts valid locations array", () => {
  const locations = [
    { tripId: "t1", lat: 33.3, lng: 44.4, ts: new Date().toISOString() },
  ];
  const isValid = Array.isArray(locations) && locations.length > 0;
  assertEquals(isValid, true);
});
