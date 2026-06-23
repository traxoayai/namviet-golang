CREATE OR REPLACE FUNCTION public.toggle_portal_user_status(p_portal_user_id uuid, p_new_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF p_new_status NOT IN ('active', 'inactive') THEN
    RAISE EXCEPTION 'Status không hợp lệ. Chỉ chấp nhận active hoặc inactive.';
  END IF;

  UPDATE portal_users
  SET status = p_new_status, updated_at = now()
  WHERE id = p_portal_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Portal user không tồn tại.';
  END IF;
END;
$function$
