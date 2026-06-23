CREATE OR REPLACE FUNCTION public.approve_user(p_user_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.check_rpc_access('approve_user');

  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Không thể tự duyệt chính mình.';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.users WHERE id = p_user_id AND status = 'pending_approval'
  ) THEN
    RAISE EXCEPTION 'User không tồn tại hoặc không ở trạng thái chờ duyệt.';
  END IF;

  UPDATE public.users
  SET status = 'active', profile_updated_at = now()
  WHERE id = p_user_id;
END;
$function$
