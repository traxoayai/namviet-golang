CREATE OR REPLACE FUNCTION public.rollback_vat_export_entry(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_invoice RECORD;
  v_item JSONB;
  v_product_id BIGINT;
  v_unit_name TEXT;
  v_qty_input NUMERIC;
  v_vat_rate NUMERIC;
  v_conversion_rate NUMERIC;
  v_qty_base NUMERIC;
  v_add_value NUMERIC;
BEGIN
  PERFORM public.check_rpc_access('rollback_vat_export_entry');

  SELECT * INTO v_invoice FROM public.finance_invoices WHERE id = p_invoice_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hoa don #% khong ton tai', p_invoice_id;
  END IF;

  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_invoice.items_json, '[]'::JSONB))
  LOOP
    v_qty_input := COALESCE((v_item->>'quantity')::NUMERIC, 0);
    IF v_qty_input <= 0 THEN CONTINUE; END IF;

    v_unit_name := COALESCE(NULLIF(TRIM(v_item->>'unit'), ''), NULLIF(TRIM(v_item->>'internal_unit'), ''));
    v_vat_rate := COALESCE((v_item->>'vat_rate')::NUMERIC, 0);
    v_product_id := (v_item->>'product_id')::BIGINT;
    IF v_product_id IS NULL THEN CONTINUE; END IF;

    -- Find conversion rate
    SELECT conversion_rate INTO v_conversion_rate
    FROM public.product_units
    WHERE product_id = v_product_id AND LOWER(unit_name) = LOWER(v_unit_name)
    LIMIT 1;
    
    IF v_conversion_rate IS NULL THEN
      SELECT conversion_rate INTO v_conversion_rate
      FROM public.product_units
      WHERE product_id = v_product_id
      ORDER BY is_base DESC, conversion_rate ASC
      LIMIT 1;
    END IF;

    IF v_conversion_rate IS NULL THEN CONTINUE; END IF;

    v_qty_base := v_qty_input * v_conversion_rate;
    -- Approximate the value added back using the pre_vat_price
    v_add_value := COALESCE((v_item->>'pre_vat_price')::NUMERIC, 0) * v_qty_input;

    UPDATE public.vat_inventory_ledger
    SET quantity_balance = quantity_balance + v_qty_base,
        total_value_balance = total_value_balance + v_add_value,
        updated_at = NOW()
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate;
  END LOOP;
END;
$function$
