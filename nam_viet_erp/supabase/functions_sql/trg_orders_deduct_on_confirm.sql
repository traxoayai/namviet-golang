CREATE OR REPLACE FUNCTION public.trg_orders_deduct_on_confirm()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF NEW.status = 'CONFIRMED'
     AND OLD.status IS DISTINCT FROM 'CONFIRMED'
     AND NEW.order_type = 'B2B' THEN
    PERFORM public._confirm_deduct_stock(NEW.id);
  END IF;
  RETURN NEW;
END;
$function$
