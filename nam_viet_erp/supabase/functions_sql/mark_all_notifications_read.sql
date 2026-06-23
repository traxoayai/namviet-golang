CREATE OR REPLACE FUNCTION public.mark_all_notifications_read(p_customer_b2b_id bigint)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_count INT;
BEGIN
  UPDATE public.b2b_notifications
  SET is_read = true,
      read_at = now()
  WHERE (customer_b2b_id = p_customer_b2b_id OR customer_b2b_id IS NULL)
    AND is_read = false;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$function$
