CREATE OR REPLACE FUNCTION public.user_has_permission(p_permission text)
 RETURNS boolean
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT EXISTS (
    SELECT 1
    FROM public.role_permissions rp
    JOIN public.user_roles ur ON ur.role_id = rp.role_id
    WHERE ur.user_id = auth.uid()
      AND (rp.permission_key = p_permission OR rp.permission_key = 'admin-all')
  );
$function$
