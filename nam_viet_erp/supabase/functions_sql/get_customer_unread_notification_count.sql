CREATE OR REPLACE FUNCTION public.get_customer_unread_notification_count(p_customer_b2b_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count INT;
BEGIN
  SELECT COUNT(*)::int INTO v_count
  FROM public.b2b_notifications n
  WHERE (n.customer_b2b_id = p_customer_b2b_id OR n.customer_b2b_id IS NULL)
    AND n.is_read = false;

  RETURN v_count;
END;
$function$
