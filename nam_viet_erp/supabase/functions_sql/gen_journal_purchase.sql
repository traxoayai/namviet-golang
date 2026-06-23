CREATE OR REPLACE FUNCTION public.gen_journal_purchase(p_book text, p_invoice_id bigint)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v RECORD; v_goods numeric; v_tax numeric; v_total numeric; v_lines jsonb;
BEGIN
  PERFORM public.check_rpc_access('gen_journal_purchase');
  SELECT * INTO v FROM public.finance_invoices WHERE id=p_invoice_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Hóa đơn #% không tồn tại', p_invoice_id; END IF;
  IF v.direction IS DISTINCT FROM 'inbound' THEN
    RAISE EXCEPTION 'gen_journal_purchase chỉ dùng cho hóa đơn MUA (inbound). HĐ #% có direction=%', p_invoice_id, COALESCE(v.direction,'(null)');
  END IF;
  v_goods := COALESCE(v.total_amount_pre_tax,0);
  v_tax   := COALESCE(v.tax_amount,0);
  v_total := COALESCE(v.total_amount_post_tax, v_goods+v_tax);
  v_lines := jsonb_build_array(
    jsonb_build_object('account_code','156','debit',v_goods,'credit',0,'description','Tiền hàng'),
    jsonb_build_object('account_code','1331','debit',v_tax,'credit',0,'description','Thuế GTGT đầu vào'),
    jsonb_build_object('account_code','331','debit',0,'credit',v_total,
                       'partner_id', COALESCE(v.supplier_id::text, v.supplier_tax_code),'description','Phải trả NCC'));
  IF v_tax = 0 THEN v_lines := v_lines - 1; END IF; -- bỏ dòng thuế nếu = 0
  RETURN public.acc_create_journal_entry(p_book, COALESCE(v.invoice_date, current_date), 'purchase',
    'finance_invoices', p_invoice_id::text, 'Mua hàng HĐ '||COALESCE(v.invoice_number,''), v_lines);
END $function$
