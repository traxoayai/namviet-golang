CREATE OR REPLACE FUNCTION public.notify_users_by_permission(p_permission_key text, p_title text, p_message text, p_type text DEFAULT 'info'::text, p_category text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  INSERT INTO public.notifications (user_id, title, message, type, category, metadata, created_at, is_read)
  SELECT DISTINCT ur.user_id, p_title, p_message, p_type, p_category, p_metadata, NOW(), false
  FROM public.role_permissions rp
  JOIN public.user_roles ur ON rp.role_id = ur.role_id
  WHERE rp.permission_key = p_permission_key;
END;
$function$
