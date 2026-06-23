CREATE OR REPLACE FUNCTION public.delete_asset(p_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  DELETE FROM public.assets WHERE id = p_id;
END;
$function$
