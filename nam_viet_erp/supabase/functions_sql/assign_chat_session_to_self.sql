CREATE OR REPLACE FUNCTION public.assign_chat_session_to_self(p_session_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_uid uuid := auth.uid();
BEGIN
  IF v_uid IS NULL OR NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền nhận phiên' USING ERRCODE = '42501';
  END IF;

  UPDATE public.chat_sessions
     SET assigned_sales_id = v_uid,
         status            = 'human',
         last_activity_at  = now()
   WHERE id = p_session_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy phiên chat' USING ERRCODE = 'P0002';
  END IF;

  UPDATE public.chat_handoffs
     SET resolved_at = now()
   WHERE session_id  = p_session_id
     AND resolved_at IS NULL;
END;
$function$
