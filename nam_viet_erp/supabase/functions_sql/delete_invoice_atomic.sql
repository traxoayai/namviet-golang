CREATE OR REPLACE FUNCTION public.delete_invoice_atomic(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  -- Gọi check quyền (nếu hệ thống có hàm này, giữ lại, còn không thì comment out)
  -- PERFORM public.check_rpc_access('delete_invoice_atomic');

  -- 1. Revert kho VAT trước (nếu là verified)
  PERFORM public.reverse_vat_invoice_entry(p_invoice_id);

  -- 2. Xóa các dữ liệu liên quan (Allocations)
  DELETE FROM public.finance_invoice_allocations WHERE invoice_id = p_invoice_id;
  
  -- 3. Xóa hóa đơn (Các item trong finance_invoice_items sẽ tự động bị xóa theo nhờ ON DELETE CASCADE)
  DELETE FROM public.finance_invoices WHERE id = p_invoice_id;
END;
$function$
