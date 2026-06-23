CREATE OR REPLACE FUNCTION public.trg_orders_restock_on_cancel()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'CANCELLED'
     AND OLD.status IS DISTINCT FROM 'CANCELLED' THEN
    PERFORM public._cancel_restock(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$
