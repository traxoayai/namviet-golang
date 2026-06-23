CREATE OR REPLACE FUNCTION public.delete_purchase_order(p_po_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.check_rpc_access('delete_purchase_order');

  IF NOT EXISTS (
    SELECT 1 FROM public.purchase_orders WHERE id = p_po_id AND status = 'DRAFT'
  ) THEN
    RAISE EXCEPTION 'Chỉ có thể xóa đơn hàng ở trạng thái Nháp.';
  END IF;

  DELETE FROM public.purchase_order_items WHERE purchase_order_id = p_po_id;
  DELETE FROM public.purchase_orders WHERE id = p_po_id;
END;
$function$
