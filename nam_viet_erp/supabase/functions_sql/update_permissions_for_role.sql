CREATE OR REPLACE FUNCTION public.update_permissions_for_role(p_role_id uuid, p_permission_keys text[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.check_rpc_access('update_permissions_for_role');

  DELETE FROM public.role_permissions WHERE role_id = p_role_id;

  INSERT INTO public.role_permissions (role_id, permission_key)
  SELECT p_role_id, unnest(p_permission_keys);
END;
$function$
