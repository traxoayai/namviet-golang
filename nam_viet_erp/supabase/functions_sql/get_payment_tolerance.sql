CREATE OR REPLACE FUNCTION public.get_payment_tolerance()
 RETURNS numeric
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT COALESCE(
    (SELECT (value#>>'{}')::numeric
     FROM public.system_settings
     WHERE key = 'payment_tolerance'),
    100
  );
$function$
