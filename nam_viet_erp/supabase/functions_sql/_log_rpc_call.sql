CREATE OR REPLACE FUNCTION public._log_rpc_call(p_module text, p_action text, p_data jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user_id UUID;
  v_user_name TEXT := 'Hệ thống';
BEGIN
  v_user_id := auth.uid();
  IF v_user_id IS NOT NULL THEN
    SELECT COALESCE(full_name, email, 'Unknown')
    INTO v_user_name
    FROM public.users WHERE id = v_user_id;
  END IF;

  INSERT INTO public.system_logs (
    user_id, user_name, module, action,
    record_id, new_data, created_at
  ) VALUES (
    v_user_id, v_user_name, p_module, p_action,
    COALESCE(p_data->>'ref_id', ''),
    p_data,
    NOW()
  );
END;
$function$
