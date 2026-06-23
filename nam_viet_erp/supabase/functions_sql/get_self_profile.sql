CREATE OR REPLACE FUNCTION public.get_self_profile()
 RETURNS SETOF users
 LANGUAGE sql
 SECURITY DEFINER
AS $function$
  SELECT *
  FROM public.users
  WHERE id = auth.uid();
$function$
