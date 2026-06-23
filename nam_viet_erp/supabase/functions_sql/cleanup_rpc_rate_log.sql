CREATE OR REPLACE FUNCTION public.cleanup_rpc_rate_log()
 RETURNS void
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  DELETE FROM public.rpc_rate_log WHERE called_at < now() - interval '5 minutes';
$function$
