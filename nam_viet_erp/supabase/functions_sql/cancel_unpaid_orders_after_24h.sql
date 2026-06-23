CREATE OR REPLACE FUNCTION public.cancel_unpaid_orders_after_24h()
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE public.orders
  SET status = 'CANCELLED',
      updated_at = NOW(),
      note = COALESCE(note, '') || ' [Tự động hủy do chờ thanh toán quá 24h]'
  WHERE status = 'PENDING'
    AND payment_status = 'unpaid'
    AND created_at < (NOW() - INTERVAL '24 hours');
END;
$function$
