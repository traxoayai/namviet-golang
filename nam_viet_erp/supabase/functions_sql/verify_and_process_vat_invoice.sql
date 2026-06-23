CREATE OR REPLACE FUNCTION public.verify_and_process_vat_invoice(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_status text;
BEGIN
  PERFORM public.check_rpc_access('verify_and_process_vat_invoice');

  SELECT status INTO v_status
  FROM public.finance_invoices
  WHERE id = p_invoice_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hóa đơn #% không tồn tại', p_invoice_id;
  END IF;

  -- Đã verified rồi -> không nhập kho lần 2 (idempotent)
  IF v_status = 'verified' THEN
    RETURN;
  END IF;

  IF v_status <> 'draft' THEN
    RAISE EXCEPTION 'Không thể verify: Hóa đơn đang ở trạng thái "%"', v_status;
  END IF;

  UPDATE public.finance_invoices SET status = 'verified' WHERE id = p_invoice_id;

  -- Cùng transaction: nhập kho lỗi -> rollback set verified ở trên.
  PERFORM public.process_vat_invoice_entry(p_invoice_id);
END;
$function$
