CREATE OR REPLACE FUNCTION public.send_sales_reply(p_session_id uuid, p_content text)
 RETURNS chat_messages
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_msg public.chat_messages;
  v_content text := btrim(COALESCE(p_content, ''));
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền gửi tin sales' USING ERRCODE = '42501';
  END IF;

  IF char_length(v_content) = 0 THEN
    RAISE EXCEPTION 'Nội dung tin nhắn không được để trống' USING ERRCODE = '22023';
  END IF;

  -- Đảm bảo phiên tồn tại để FK insert không lỗi mơ hồ
  PERFORM 1 FROM public.chat_sessions WHERE id = p_session_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy phiên chat' USING ERRCODE = 'P0002';
  END IF;

  INSERT INTO public.chat_messages (session_id, role, content_type, content)
  VALUES (p_session_id, 'sales', 'text', v_content)
  RETURNING * INTO v_msg;

  UPDATE public.chat_sessions
     SET last_activity_at = now()
   WHERE id = p_session_id;

  RETURN v_msg;
END;
$function$
