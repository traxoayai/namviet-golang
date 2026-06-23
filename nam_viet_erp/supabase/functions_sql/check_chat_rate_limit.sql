CREATE OR REPLACE FUNCTION public.check_chat_rate_limit(p_user_id uuid, p_max integer DEFAULT 60, p_window_sec integer DEFAULT 60)
 RETURNS TABLE(ok boolean, remaining integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_window_start timestamptz;
  v_new_count    int;
BEGIN
  IF p_user_id IS NULL THEN
    -- Defensive: caller phải pass uuid hợp lệ. Trả ok=false để không bị bypass.
    RETURN QUERY SELECT false, 0;
    RETURN;
  END IF;

  -- Floor xuống đầu window_sec gần nhất → mọi request trong cùng phút share row.
  v_window_start := to_timestamp(
    floor(extract(epoch FROM now()) / p_window_sec) * p_window_sec
  );

  -- Atomic check-then-increment: nếu row chưa tới max thì +1, ngược lại giữ
  -- nguyên. ON CONFLICT update có guard WHERE để không tăng quá max.
  INSERT INTO public.chat_rate_limit (user_id, window_start, count, updated_at)
  VALUES (p_user_id, v_window_start, 1, now())
  ON CONFLICT (user_id, window_start) DO UPDATE
    SET count      = public.chat_rate_limit.count + 1,
        updated_at = now()
    WHERE public.chat_rate_limit.count < p_max
  RETURNING public.chat_rate_limit.count INTO v_new_count;

  IF v_new_count IS NULL THEN
    -- ON CONFLICT update bị skip (count đã >= max) → đọc lại count hiện tại.
    SELECT c.count INTO v_new_count
    FROM public.chat_rate_limit c
    WHERE c.user_id = p_user_id
      AND c.window_start = v_window_start;
    RETURN QUERY SELECT false, GREATEST(p_max - v_new_count, 0);
    RETURN;
  END IF;

  RETURN QUERY SELECT (v_new_count <= p_max), GREATEST(p_max - v_new_count, 0);
END;
$function$
