CREATE OR REPLACE FUNCTION public.get_my_permissions()
 RETURNS text[]
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
      SELECT COALESCE(array_agg(DISTINCT rp.permission_key), '{}')
      FROM public.user_roles ur
      JOIN public.role_permissions rp ON ur.role_id = rp.role_id
      WHERE ur.user_id = auth.uid();
    $function$
