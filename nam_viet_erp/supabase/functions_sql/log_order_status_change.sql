CREATE OR REPLACE FUNCTION public.log_order_status_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  IF OLD.status IS DISTINCT FROM NEW.status THEN
    INSERT INTO public.order_status_history (order_id, old_status, new_status, changed_by, reason)
    VALUES (
      NEW.id,
      OLD.status,
      NEW.status,
      auth.uid(),
      CASE
        WHEN OLD.status = 'PENDING' AND NEW.status = 'CONFIRMED' THEN 'payment_received'
        WHEN NEW.status = 'CANCELLED' THEN 'cancelled'
        WHEN NEW.status = 'PACKED' THEN 'packed'
        WHEN NEW.status = 'SHIPPING' THEN 'shipping'
        WHEN NEW.status = 'DELIVERED' THEN 'delivered'
        WHEN NEW.status = 'COMPLETED' THEN 'completed'
        ELSE 'manual_update'
      END
    );
  END IF;
  RETURN NEW;
END;
$function$
