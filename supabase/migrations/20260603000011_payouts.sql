-- Migration: 20260603000011_payouts.sql
-- Description: Driver payout requests

CREATE TABLE public.driver_payouts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  driver_id UUID NOT NULL REFERENCES public.drivers(id) ON DELETE CASCADE,
  amount NUMERIC(12, 2) NOT NULL CHECK (amount > 0),
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending', 'completed', 'rejected')),
  reference_note TEXT,
  rejection_reason TEXT,
  processed_by UUID REFERENCES public.profiles(id),
  processed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payouts_driver ON public.driver_payouts(driver_id);
CREATE INDEX idx_payouts_status ON public.driver_payouts(status);
CREATE INDEX idx_payouts_created ON public.driver_payouts(created_at DESC);

ALTER TABLE public.driver_payouts ENABLE ROW LEVEL SECURITY;

-- Drivers can read their own payouts
CREATE POLICY "payouts_select_own"
  ON public.driver_payouts FOR SELECT
  TO authenticated
  USING (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Drivers can create their own payout requests
CREATE POLICY "payouts_insert_own_driver"
  ON public.driver_payouts FOR INSERT
  TO authenticated
  WITH CHECK (
    driver_id IN (SELECT id FROM public.drivers WHERE user_id = auth.uid())
  );

-- Admins can manage all
CREATE POLICY "payouts_all_admin"
  ON public.driver_payouts FOR ALL
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE TRIGGER set_payouts_updated_at
  BEFORE UPDATE ON public.driver_payouts
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- RPC: Request a payout (with race condition protection)
CREATE OR REPLACE FUNCTION public.request_payout(
  p_amount NUMERIC
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_driver_id UUID;
  v_total_earned NUMERIC;
  v_total_withdrawn NUMERIC;
  v_available NUMERIC;
  v_payout_id UUID;
BEGIN
  -- Get the driver's record (lock it)
  SELECT id INTO v_driver_id
  FROM public.drivers
  WHERE user_id = auth.uid()
  FOR UPDATE;

  IF v_driver_id IS NULL THEN
    RAISE EXCEPTION 'Not a driver'
      USING ERRCODE = 'P0001';
  END IF;

  -- Calculate available balance
  -- Total earned = sum of all completed payments for this driver's routes
  SELECT COALESCE(SUM(p.amount), 0)
  INTO v_total_earned
  FROM public.payments p
  JOIN public.subscriptions s ON p.subscription_id = s.id
  JOIN public.routes r ON s.route_id = r.id
  WHERE r.driver_id = v_driver_id
    AND p.status = 'completed';

  -- Total withdrawn
  SELECT COALESCE(SUM(amount), 0)
  INTO v_total_withdrawn
  FROM public.driver_payouts
  WHERE driver_id = v_driver_id
    AND status IN ('pending', 'completed');

  v_available := v_total_earned - v_total_withdrawn;

  IF p_amount <= 0 THEN
    RAISE EXCEPTION 'Amount must be positive'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_amount > v_available THEN
    RAISE EXCEPTION 'Insufficient balance. Available: %, Requested: %',
      v_available, p_amount
      USING ERRCODE = 'P0001';
  END IF;

  -- Create payout request
  INSERT INTO public.driver_payouts (driver_id, amount, status)
  VALUES (v_driver_id, p_amount, 'pending')
  RETURNING id INTO v_payout_id;

  RETURN v_payout_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.request_payout(NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.request_payout(NUMERIC) TO authenticated;

-- RPC: Update payout status (admin only)
CREATE OR REPLACE FUNCTION public.update_payout_status(
  p_payout_id UUID,
  p_new_status TEXT,
  p_note TEXT DEFAULT NULL
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Admin only'
      USING ERRCODE = 'P0001';
  END IF;

  IF p_new_status NOT IN ('completed', 'rejected') THEN
    RAISE EXCEPTION 'Invalid status: %', p_new_status
      USING ERRCODE = 'P0001';
  END IF;

  UPDATE public.driver_payouts
  SET status = p_new_status,
      reference_note = COALESCE(p_note, reference_note),
      processed_by = auth.uid(),
      processed_at = NOW(),
      updated_at = NOW()
  WHERE id = p_payout_id;
END;
$$;

REVOKE EXECUTE ON FUNCTION public.update_payout_status(UUID, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.update_payout_status(UUID, TEXT, TEXT) TO authenticated;
