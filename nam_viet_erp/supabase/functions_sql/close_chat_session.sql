CREATE OR REPLACE FUNCTION public.close_chat_session(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền đóng phiên' USING ERRCODE = '42501';
  END IF;

  UPDATE public.chat_sessions
     SET status           = 'closed',
         closed_at        = now(),
         last_activity_at = now()
   WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy phiên chat' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.chat_messages (session_id, role, content_type, content)
  VALUES (
    p_session_id,
    'system',
    'text',
    'Phiên đã được đóng. Cảm ơn anh chị.'
  );
END;
$function$
