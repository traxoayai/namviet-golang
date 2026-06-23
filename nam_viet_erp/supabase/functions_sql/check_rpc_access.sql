CREATE OR REPLACE FUNCTION public.check_rpc_access(p_function_name text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_rule RECORD;
  v_call_count INT;
  v_uid UUID;
BEGIN
  v_uid := auth.uid();

  -- Must be authenticated
  IF v_uid IS NULL THEN
    RAISE EXCEPTION 'Unauthorized: Chưa đăng nhập.';
  END IF;

  -- Lookup rule
  SELECT * INTO v_rule FROM public.rpc_access_rules WHERE function_name = p_function_name;

  -- No rule = allow authenticated (backward compatible)
  IF NOT FOUND THEN
    RETURN;
  END IF;

  -- Permission check
  IF v_rule.required_permission IS NOT NULL THEN
    IF NOT public.user_has_permission(v_rule.required_permission)
       AND NOT public.user_has_permission('admin-all') THEN
      RAISE EXCEPTION 'Forbidden: Bạn không có quyền gọi %.', p_function_name;
    END IF;
  END IF;

  -- Rate limit check
  IF v_rule.max_calls_per_minute > 0 THEN
    SELECT COUNT(*) INTO v_call_count
    FROM public.rpc_rate_log
    WHERE user_id = v_uid
      AND function_name = p_function_name
      AND called_at > now() - interval '1 minute';

    IF v_call_count >= v_rule.max_calls_per_minute THEN
      RAISE EXCEPTION 'Rate limit exceeded: Vượt quá % lần/phút cho %.', v_rule.max_calls_per_minute, p_function_name;
    END IF;
  END IF;

  -- Log call to rate_log
  INSERT INTO public.rpc_rate_log (user_id, function_name) VALUES (v_uid, p_function_name);

  -- Auto-log WRITE operations to system_logs for audit trail
  IF v_rule.is_write THEN
    PERFORM public._log_rpc_call(
      SPLIT_PART(COALESCE(v_rule.required_permission, 'system'), '.', 1),
      p_function_name,
      jsonb_build_object('user_id', v_uid)
    );
  END IF;
END;
$function$
