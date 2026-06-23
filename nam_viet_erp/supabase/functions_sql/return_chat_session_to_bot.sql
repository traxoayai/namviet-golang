CREATE OR REPLACE FUNCTION public.return_chat_session_to_bot(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_current_status text;
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền trả phiên về bot' USING ERRCODE = '42501';
  END IF;

  SELECT status INTO v_current_status
  FROM public.chat_sessions
  WHERE id = p_session_id;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy phiên chat' USING ERRCODE = 'P0002';
  END IF;

  IF v_current_status NOT IN ('human', 'handoff_pending') THEN
    RAISE EXCEPTION 'Chỉ trả về bot từ trạng thái human hoặc handoff_pending'
      USING ERRCODE = '22023';
  END IF;

  UPDATE public.chat_sessions
     SET status            = 'bot',
         assigned_sales_id = NULL,
         last_activity_at  = now()
   WHERE id = p_session_id;
END;
$function$
