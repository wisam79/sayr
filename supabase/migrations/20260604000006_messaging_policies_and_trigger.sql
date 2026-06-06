-- Migration: 20260604000006_messaging_policies_and_trigger.sql
-- Description: Policies for messaging and triggers for auto-updating conversations and push notifications

-- 1. Enable pg_net extension if not enabled
CREATE EXTENSION IF NOT EXISTS "pg_net" WITH SCHEMA extensions;

-- 2. Add INSERT policy to public.conversations
CREATE POLICY "conversations_insert_participants"
  ON public.conversations FOR INSERT
  TO authenticated
  WITH CHECK (
    student_id = auth.uid() OR driver_user_id = auth.uid()
  );

-- 3. Add UPDATE policy to public.messages for marking read status
CREATE POLICY "messages_update_recipient"
  ON public.messages FOR UPDATE
  TO authenticated
  USING (
    conversation_id IN (
      SELECT id FROM public.conversations
      WHERE student_id = auth.uid() OR driver_user_id = auth.uid()
    )
  );

-- 4. Create trigger to auto-update last_message_at and last_message_preview in conversations on new message
CREATE OR REPLACE FUNCTION public.handle_new_message()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE public.conversations
  SET last_message_at = NEW.created_at,
      last_message_preview = SUBSTRING(NEW.body FROM 1 FOR 100),
      updated_at = NOW()
  WHERE id = NEW.conversation_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.handle_new_message() FROM PUBLIC, anon;

CREATE TRIGGER on_new_message
  AFTER INSERT ON public.messages
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_message();

-- 5. Create trigger on public.notification_log to dynamically invoke send-push-notification edge function
CREATE OR REPLACE FUNCTION public.trigger_send_push()
RETURNS TRIGGER AS $$
DECLARE
  v_service_key TEXT;
  v_url TEXT;
BEGIN
  -- Retrieve service_role_key from decrypted vault secrets
  SELECT decrypted_secret INTO v_service_key
  FROM vault.decrypted_secrets
  WHERE name = 'service_role_key'
  LIMIT 1;

  -- Fallback if running locally and service_role_key is not in vault yet
  IF v_service_key IS NULL THEN
    v_service_key := current_setting('request.headers', true)::json ->> 'apikey';
  END IF;

  -- Determine Supabase local vs production functions URL
  v_url := 'http://kong:8000/functions/v1/send-push-notification';

  PERFORM net.http_post(
    url := v_url,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', CONCAT('Bearer ', COALESCE(v_service_key, ''))
    ),
    body := jsonb_build_object(
      'userId', NEW.user_id,
      'title', NEW.title,
      'body', NEW.body,
      'data', NEW.data
    )::text
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.trigger_send_push() FROM PUBLIC, anon;

CREATE TRIGGER on_notification_logged
  AFTER INSERT ON public.notification_log
  FOR EACH ROW
  EXECUTE FUNCTION public.trigger_send_push();
