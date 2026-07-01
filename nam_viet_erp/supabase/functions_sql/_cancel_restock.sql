CREATE OR REPLACE FUNCTION public._cancel_restock(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.handle_order_cancellation(p_order_id);
END;
$function$
