CREATE OR REPLACE FUNCTION public._test_find_auth_user_by_email(p_email text)
 RETURNS uuid
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'auth', 'pg_catalog'
AS $function$
  SELECT id FROM auth.users WHERE email = p_email LIMIT 1;
$function$
