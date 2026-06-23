CREATE OR REPLACE FUNCTION public.mark_notification_read(p_notification_id uuid, p_customer_b2b_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  UPDATE public.b2b_notifications
  SET is_read = true,
      read_at = now()
  WHERE id = p_notification_id
    AND (customer_b2b_id = p_customer_b2b_id OR customer_b2b_id IS NULL)
    AND is_read = false;

  RETURN FOUND;
END;
$function$
