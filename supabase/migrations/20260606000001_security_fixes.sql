-- Migration: 20260606000001_security_fixes.sql
-- Description: Security and logic hotfixes for RLS policies, rate limits, payouts, chats, ratings, and license activations.

-- 1. Fix create_payment RPC to validate amount against route price
CREATE OR REPLACE FUNCTION public.create_payment(
  p_route_id UUID,
  p_amount NUMERIC,
  p_currency TEXT,
  p_method TEXT
)
RETURNS public.payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license_id UUID;
  v_valid_days INTEGER;
  v_subscription_id UUID;
  v_status TEXT;
  v_payment public.payments;
  v_route_price NUMERIC;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated'
      USING ERRCODE = 'P0001';
  END IF;

  -- Validate route and get its price
  SELECT price INTO v_route_price FROM public.routes WHERE id = p_route_id AND is_active = true;
  IF v_route_price IS NULL THEN
    RAISE EXCEPTION 'Route not found or inactive'
      USING ERRCODE = 'P0001';
  END IF;

  -- Verify amount matches actual route price
  IF p_amount != v_route_price THEN
    RAISE EXCEPTION 'Incorrect payment amount. Expected %, Got %', v_route_price, p_amount
      USING ERRCODE = 'P0001';
  END IF;

  -- Check existing subscription
  SELECT id, license_id, status INTO v_subscription_id, v_license_id, v_status
  FROM public.subscriptions
  WHERE student_id = auth.uid()
    AND route_id = p_route_id
    AND status IN ('active', 'pending')
  LIMIT 1;

  IF FOUND THEN
    IF v_status = 'active' THEN
      RAISE EXCEPTION 'You already have an active subscription for this route'
        USING ERRCODE = 'P0001';
    END IF;
  ELSE
    -- Find an active, unclaimed license
    SELECT l.id, l.valid_days INTO v_license_id, v_valid_days
    FROM public.licenses l
    WHERE l.route_id = p_route_id
      AND l.status = 'active'
      AND l.used_by IS NULL
      AND NOT EXISTS (
        SELECT 1 FROM public.subscriptions s
        WHERE s.license_id = l.id
          AND s.status IN ('active', 'pending')
      )
    LIMIT 1
    FOR UPDATE SKIP LOCKED;

    IF v_license_id IS NULL THEN
      RAISE EXCEPTION 'No licenses available for this route'
        USING ERRCODE = 'P0001';
    END IF;

    -- Create pending subscription
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      p_route_id,
      v_license_id,
      'pending',
      NOW(),
      NOW() + (v_valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;
  END IF;

  -- Create pending payment
  INSERT INTO public.payments (
    user_id,
    subscription_id,
    license_id,
    amount,
    currency,
    method,
    status
  )
  VALUES (
    auth.uid(),
    v_subscription_id,
    v_license_id,
    p_amount,
    p_currency,
    p_method,
    'pending'
  )
  RETURNING * INTO v_payment;

  RETURN v_payment;
END;
$$;


-- 2. Fix activate_license RPC to consume card, deduct seats, and activate subscription immediately
CREATE OR REPLACE FUNCTION public.activate_license(
  p_code TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_license RECORD;
  v_subscription_id UUID;
  v_existing_sub UUID;
BEGIN
  -- Rate limit: max 5 attempts per 15 minutes
  IF NOT public.check_rate_limit(
    auth.uid(),
    'activate_license',
    5,
    900
  ) THEN
    RAISE EXCEPTION 'Too many activation attempts. Please try again later.'
      USING ERRCODE = 'P0001';
  END IF;

  -- Normalize code
  p_code := UPPER(TRIM(p_code));

  -- Validate format
  IF p_code !~ '^[A-Z0-9]{8}$' THEN
    RAISE EXCEPTION 'Invalid license code format'
      USING ERRCODE = 'P0001';
  END IF;

  -- Lock license
  SELECT id, route_id, status, used_by, valid_days
  INTO v_license
  FROM public.licenses
  WHERE code = p_code
  FOR UPDATE NOWAIT;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'License code not found'
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.status != 'active' THEN
    RAISE EXCEPTION 'License is not active (status: %)', v_license.status
      USING ERRCODE = 'P0001';
  END IF;

  IF v_license.used_by IS NOT NULL THEN
    RAISE EXCEPTION 'License already used'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check if user already has active subscription for this route
  SELECT id INTO v_existing_sub
  FROM public.subscriptions
  WHERE student_id = auth.uid()
    AND route_id = v_license.route_id
    AND status IN ('active', 'pending');

  IF v_existing_sub IS NOT NULL THEN
    RAISE EXCEPTION 'You already have an active subscription for this route'
      USING ERRCODE = 'P0001';
  END IF;

  -- Check seat availability
  IF NOT EXISTS (
    SELECT 1 FROM public.routes
    WHERE id = v_license.route_id AND available_seats > 0
  ) THEN
    RAISE EXCEPTION 'No seats available on route'
      USING ERRCODE = 'P0001';
  END IF;

  -- 1. Create active subscription
  BEGIN
    INSERT INTO public.subscriptions (
      student_id, route_id, license_id, status, start_date, end_date
    )
    VALUES (
      auth.uid(),
      v_license.route_id,
      v_license.id,
      'active',
      NOW(),
      NOW() + (v_license.valid_days || ' days')::interval
    )
    RETURNING id INTO v_subscription_id;
  EXCEPTION
    WHEN unique_violation THEN
      RAISE EXCEPTION 'Duplicate subscription detected'
        USING ERRCODE = 'P0001';
  END;

  -- 2. Deduct seat from route
  UPDATE public.routes
  SET available_seats = available_seats - 1,
      updated_at = NOW()
  WHERE id = v_license.route_id
    AND available_seats > 0;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'No seats available on route during activation'
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Mark license as used
  UPDATE public.licenses
  SET status = 'used',
      used_by = auth.uid(),
      used_at = NOW()
  WHERE id = v_license.id;

  -- 4. Audit log
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'license_activated_via_voucher',
    'license',
    v_license.id,
    jsonb_build_object(
      'subscription_id', v_subscription_id,
      'route_id', v_license.route_id
    )
  );

  RETURN v_subscription_id;
END;
$$;


-- 3. Fix messages Table Security (prevent message body/sender tampering via trigger)
DROP POLICY IF EXISTS "messages_update_recipient" ON public.messages;

CREATE POLICY "messages_update_recipient"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM public.conversations
      WHERE student_id = auth.uid() OR driver_user_id = auth.uid()
    )
  );

-- Trigger function to enforce immutability of sent messages
CREATE OR REPLACE FUNCTION public.enforce_message_immutability()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.body != OLD.body THEN
    RAISE EXCEPTION 'Cannot modify message body' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.sender_id != OLD.sender_id THEN
    RAISE EXCEPTION 'Cannot modify message sender' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.conversation_id != OLD.conversation_id THEN
    RAISE EXCEPTION 'Cannot modify message conversation' USING ERRCODE = 'P0001';
  END IF;
  IF NEW.created_at != OLD.created_at THEN
    RAISE EXCEPTION 'Cannot modify message creation time' USING ERRCODE = 'P0001';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_enforce_message_immutability ON public.messages;
CREATE TRIGGER trigger_enforce_message_immutability
  BEFORE UPDATE ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_message_immutability();


-- 4. Fix conversations Table Security (restrict insert to actual route driver)
DROP POLICY IF EXISTS "conversations_insert_participants" ON public.conversations;

CREATE POLICY "conversations_insert_participants"
  ON public.conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    (student_id = auth.uid() OR driver_user_id = auth.uid())
    AND driver_user_id = (
      SELECT d.user_id
      FROM public.routes r
      JOIN public.drivers d ON r.driver_id = d.id
      WHERE r.id = route_id
    )
  );


-- 5. Fix driver_payouts Table Security (disable direct INSERT for drivers)
DROP POLICY IF EXISTS "payouts_insert_own_driver" ON public.driver_payouts;


-- 6. Fix ratings Table Security (enforce matching trip driver and completed status)
DROP POLICY IF EXISTS "ratings_insert_own_student" ON public.ratings;

CREATE POLICY "ratings_insert_own_student"
  ON public.ratings FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid()
    AND EXISTS (
      SELECT 1 FROM public.subscriptions s
      JOIN public.trips t ON t.route_id = s.route_id
      WHERE s.student_id = auth.uid()
        AND t.id = trip_id
        AND t.driver_id = driver_id
        AND t.status = 'completed'
    )
  );


-- 7. Fix check_rate_limit RPC (fix time window math)
CREATE OR REPLACE FUNCTION public.check_rate_limit(
  p_user_id UUID,
  p_action TEXT,
  p_limit INTEGER,
  p_window_seconds INTEGER
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
  v_window_start TIMESTAMPTZ;
BEGIN
  -- Group window starts by rounding down current epoch seconds to nearest p_window_seconds
  v_window_start := to_timestamp(
    floor(extract(epoch from NOW()) / p_window_seconds) * p_window_seconds
  );

  -- Get or create rate limit record
  INSERT INTO public.rate_limits (user_id, action, count, window_start, expires_at)
  VALUES (
    p_user_id,
    p_action,
    1,
    v_window_start,
    v_window_start + (p_window_seconds || ' seconds')::interval
  )
  ON CONFLICT (user_id, action, window_start)
  DO UPDATE SET count = rate_limits.count + 1
  RETURNING count INTO v_count;

  RETURN v_count <= p_limit;
END;
$$;


-- 8. Fix support_requests Table Security (prevent tampering with response/assignment)
DROP POLICY IF EXISTS "support_all_own" ON public.support_requests;
DROP POLICY IF EXISTS "support_select_own" ON public.support_requests;
DROP POLICY IF EXISTS "support_insert_own" ON public.support_requests;
DROP POLICY IF EXISTS "support_update_own" ON public.support_requests;

-- Users can read own support requests
CREATE POLICY "support_select_own"
  ON public.support_requests FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

-- Users can insert own support requests
CREATE POLICY "support_insert_own"
  ON public.support_requests FOR INSERT
  TO authenticated
  WITH CHECK (
    user_id = auth.uid()
    AND status = 'open'
    AND response IS NULL
    AND assigned_to IS NULL
    AND responded_at IS NULL
  );

-- Users can update own support requests
CREATE POLICY "support_update_own"
  ON public.support_requests FOR UPDATE
  TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Trigger to prevent users from modifying admin-controlled fields
CREATE OR REPLACE FUNCTION public.enforce_support_request_rules()
RETURNS TRIGGER AS $$
BEGIN
  IF NOT public.is_admin() THEN
    IF NEW.response IS DISTINCT FROM OLD.response THEN
      RAISE EXCEPTION 'Cannot modify response' USING ERRCODE = 'P0001';
    END IF;
    IF NEW.assigned_to IS DISTINCT FROM OLD.assigned_to THEN
      RAISE EXCEPTION 'Cannot modify assigned_to' USING ERRCODE = 'P0001';
    END IF;
    IF NEW.responded_at IS DISTINCT FROM OLD.responded_at THEN
      RAISE EXCEPTION 'Cannot modify responded_at' USING ERRCODE = 'P0001';
    END IF;
    IF OLD.status = 'closed' AND NEW.status != 'closed' THEN
      RAISE EXCEPTION 'Cannot reopen closed ticket' USING ERRCODE = 'P0001';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_enforce_support_request_rules ON public.support_requests;
CREATE TRIGGER trigger_enforce_support_request_rules
  BEFORE UPDATE ON public.support_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.enforce_support_request_rules();
