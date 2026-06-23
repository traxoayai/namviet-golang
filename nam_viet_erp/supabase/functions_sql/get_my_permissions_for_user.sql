CREATE OR REPLACE FUNCTION public.get_my_permissions_for_user(p_user_id uuid)
 RETURNS text[]
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_perms TEXT[];
BEGIN
  SELECT ARRAY_AGG(DISTINCT rp.permission_key)
  INTO v_perms
  FROM public.user_roles ur
  JOIN public.role_permissions rp ON rp.role_id = ur.role_id
  WHERE ur.user_id = p_user_id;

  RETURN COALESCE(v_perms, ARRAY[]::TEXT[]);
END;
$function$
