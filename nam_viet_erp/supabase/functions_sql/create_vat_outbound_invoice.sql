CREATE OR REPLACE FUNCTION public.create_vat_outbound_invoice(p_payload jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_id bigint;
BEGIN
  PERFORM public.check_rpc_access('create_vat_outbound_invoice');

  INSERT INTO public.finance_invoices (
    invoice_number, invoice_symbol, invoice_date, supplier_name_raw,
    buyer_tax_code, total_amount_pre_tax, tax_amount, total_amount_post_tax,
    direction, status, raw_items, created_at
  ) VALUES (
    p_payload->>'invoice_number',
    p_payload->>'invoice_symbol',
    NULLIF(p_payload->>'invoice_date', '')::date,
    p_payload->>'supplier_name_raw',
    p_payload->>'buyer_tax_code',
    COALESCE((p_payload->>'total_amount_pre_tax')::numeric, 0),
    COALESCE((p_payload->>'total_tax')::numeric, 0),
    COALESCE((p_payload->>'total_amount_post_tax')::numeric, 0),
    'outbound',
    'verified_outbound',
    p_payload->'items',
    NOW()
  )
  RETURNING id INTO v_id;

  -- Cùng transaction: nếu trừ kho RAISE (thiếu hàng / ĐVT sai) thì INSERT phía
  -- trên tự ROLLBACK. Không còn hóa đơn "ảo" chưa trừ kho như flow cũ.
  PERFORM public.process_vat_export_entry(v_id);

  RETURN v_id;
END;
$function$
