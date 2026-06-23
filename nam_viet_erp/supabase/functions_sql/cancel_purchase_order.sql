CREATE OR REPLACE FUNCTION public.cancel_purchase_order(p_po_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.check_rpc_access('cancel_purchase_order');

  IF NOT EXISTS (
    SELECT 1 FROM public.purchase_orders
    WHERE id = p_po_id AND status IN ('DRAFT', 'NEW', 'APPROVED', 'ORDERING')
  ) THEN
    RAISE EXCEPTION 'Khong the huy don hang: Don khong ton tai hoac da hoan thanh/da huy.';
  END IF;

  UPDATE public.purchase_orders
  SET status = 'CANCELLED',
      updated_at = NOW()
  WHERE id = p_po_id;
END;
$function$
