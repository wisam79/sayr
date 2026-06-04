-- Migration: 20260603000013_messaging.sql
-- Description: Chat conversations and messages

CREATE TABLE public.conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  route_id UUID NOT NULL REFERENCES public.routes(id) ON DELETE CASCADE,
  student_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  driver_user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  last_message_at TIMESTAMPTZ,
  last_message_preview TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  -- One conversation per (route, student)
  CONSTRAINT uq_conversation_per_route_student UNIQUE (route_id, student_id)
);

CREATE INDEX idx_conversations_route ON public.conversations(route_id);
CREATE INDEX idx_conversations_student ON public.conversations(student_id);
CREATE INDEX idx_conversations_driver ON public.conversations(driver_user_id);
CREATE INDEX idx_conversations_updated ON public.conversations(updated_at DESC);

ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;

-- Students can read their own conversations
CREATE POLICY "conversations_select_student"
  ON public.conversations FOR SELECT
  TO authenticated
  USING (student_id = auth.uid());

-- Drivers can read conversations for their routes
CREATE POLICY "conversations_select_driver"
  ON public.conversations FOR SELECT
  TO authenticated
  USING (driver_user_id = auth.uid());

CREATE TRIGGER set_conversations_updated_at
  BEFORE UPDATE ON public.conversations
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

CREATE TABLE public.messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (length(body) > 0 AND length(body) <= 4000),
  is_read BOOLEAN NOT NULL DEFAULT false,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id);
CREATE INDEX idx_messages_sender ON public.messages(sender_id);
CREATE INDEX idx_messages_unread ON public.messages(conversation_id, is_read)
  WHERE is_read = false;
CREATE INDEX idx_messages_created ON public.messages(created_at DESC);

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

-- Participants can read messages
CREATE POLICY "messages_select_participants"
  ON public.messages FOR SELECT
  TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM public.conversations
      WHERE student_id = auth.uid() OR driver_user_id = auth.uid()
    )
  );

-- Participants can send messages
CREATE POLICY "messages_insert_participants"
  ON public.messages FOR INSERT
  TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND conversation_id IN (
      SELECT id FROM public.conversations
      WHERE student_id = auth.uid() OR driver_user_id = auth.uid()
    )
  );

-- RPC: Get unread count
CREATE OR REPLACE FUNCTION public.get_unread_count()
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_count INTEGER;
BEGIN
  SELECT COUNT(*)::INTEGER INTO v_count
  FROM public.messages m
  JOIN public.conversations c ON m.conversation_id = c.id
  WHERE (c.student_id = auth.uid() OR c.driver_user_id = auth.uid())
    AND m.sender_id != auth.uid()
    AND m.is_read = false;

  RETURN v_count;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_unread_count() TO authenticated;
