-- Migration: 20260603000016_audit.sql
-- Description: Audit log for security-sensitive operations

CREATE TABLE public.audit_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
  action TEXT NOT NULL,
  entity_type TEXT,
  entity_id UUID,
  details JSONB NOT NULL DEFAULT '{}'::jsonb,
  ip_address INET,
  user_agent TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_user ON public.audit_logs(user_id);
CREATE INDEX idx_audit_action ON public.audit_logs(action);
CREATE INDEX idx_audit_entity ON public.audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_created ON public.audit_logs(created_at DESC);

ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Only admins can read audit logs
CREATE POLICY "audit_select_admin"
  ON public.audit_logs FOR SELECT
  TO authenticated
  USING (public.is_admin());

-- No one can modify audit logs (immutable)
-- Service role can insert (for triggers and edge functions)
CREATE POLICY "audit_insert_service"
  ON public.audit_logs FOR INSERT
  TO service_role
  WITH CHECK (true);

-- No UPDATE or DELETE policies (immutable)
