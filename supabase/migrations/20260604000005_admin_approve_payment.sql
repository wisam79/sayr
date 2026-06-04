-- Migration: 20260604000005_admin_approve_payment.sql
-- Description: Admin-only function to manually approve pending payments and activate subscriptions

CREATE OR REPLACE FUNCTION public.admin_approve_payment(
  p_payment_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_payment RECORD;
  v_sub_id UUID;
BEGIN
  -- 1. Ensure caller is authenticated and is an admin
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Not authenticated'
      USING ERRCODE = 'P0001';
  END IF;

  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  -- 2. Fetch payment details
  SELECT * INTO v_payment
  FROM public.payments
  WHERE id = p_payment_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Payment record not found'
      USING ERRCODE = 'P0001';
  END IF;

  -- 3. Verify payment is pending
  IF v_payment.status != 'pending' THEN
    RAISE EXCEPTION 'Payment is already processed (status: %)', v_payment.status
      USING ERRCODE = 'P0001';
  END IF;

  -- 4. Mark payment as completed
  UPDATE public.payments
  SET status = 'completed',
      paid_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payment_id;

  -- 5. Trigger the atomic subscription activation flow
  -- Since this RPC runs as SECURITY DEFINER, it has database owner privileges,
  -- allowing it to execute complete_payment_and_activate_subscription which is restricted to service_role.
  v_sub_id := public.complete_payment_and_activate_subscription(
    p_payment_id,
    v_payment.user_id,
    v_payment.license_id,
    v_payment.subscription_id
  );

  -- 6. Audit log the manual approval
  INSERT INTO public.audit_logs (user_id, action, entity_type, entity_id, details)
  VALUES (
    auth.uid(),
    'payment_manually_approved',
    'payment',
    p_payment_id,
    jsonb_build_object(
      'subscription_id', v_payment.subscription_id,
      'license_id', v_payment.license_id,
      'student_id', v_payment.user_id
    )
  );

  RETURN v_sub_id;
END;
$$;

-- Revoke execute from public and anon
REVOKE EXECUTE ON FUNCTION public.admin_approve_payment(UUID) FROM PUBLIC, anon;

-- Grant execute to authenticated users (admin role check is done inside the function)
GRANT EXECUTE ON FUNCTION public.admin_approve_payment(UUID) TO authenticated;
