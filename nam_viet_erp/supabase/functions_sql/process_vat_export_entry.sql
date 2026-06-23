CREATE OR REPLACE FUNCTION public.process_vat_export_entry(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
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
  v_current_balance NUMERIC;
  v_current_value NUMERIC;   -- [FIX lỗi A] giá trị tồn hiện tại
  v_value_deduct NUMERIC;    -- [FIX lỗi A] giá trị cần trừ (bình quân)
BEGIN
  -- 0. Permission guard
  PERFORM public.check_rpc_access('process_vat_export_entry');

  -- 1. Get invoice
  SELECT * INTO v_invoice FROM public.finance_invoices WHERE id = p_invoice_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hóa đơn #% không tồn tại', p_invoice_id;
  END IF;

  -- 2. Loop through raw_items
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_invoice.raw_items, '[]'::JSONB))
  LOOP
    v_qty_input := COALESCE((v_item->>'quantity')::NUMERIC, 0);
    IF v_qty_input <= 0 THEN CONTINUE; END IF;

    -- Strict unit validation: no fallback default
    v_unit_name := COALESCE(NULLIF(TRIM(v_item->>'unit'), ''), NULLIF(TRIM(v_item->>'internal_unit'), ''));
    IF v_unit_name IS NULL THEN
      RAISE EXCEPTION 'Item thieu don vi tinh (unit). Invoice #%', p_invoice_id;
    END IF;

    v_vat_rate := COALESCE((v_item->>'vat_rate')::NUMERIC, 0);

    -- Mandatory product_id: no name-based fallback
    v_product_id := (v_item->>'product_id')::BIGINT;
    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'Item thieu product_id. Invoice #%, item: %', p_invoice_id, v_item->>'product_name';
    END IF;

    -- Find conversion rate
    SELECT conversion_rate INTO v_conversion_rate
    FROM public.product_units
    WHERE product_id = v_product_id AND unit_name = v_unit_name
    LIMIT 1;
    IF v_conversion_rate IS NULL THEN
      RAISE EXCEPTION 'Khong tim thay don vi "%" cho SP #%. Invoice #%',
        v_unit_name, v_product_id, p_invoice_id;
    END IF;

    v_qty_base := v_qty_input * v_conversion_rate;

    -- Check VAT inventory (with FOR UPDATE lock) — lấy thêm total_value_balance
    SELECT quantity_balance, total_value_balance
      INTO v_current_balance, v_current_value
    FROM public.vat_inventory_ledger
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate
    FOR UPDATE;

    IF NOT FOUND OR v_current_balance < v_qty_base THEN
      RAISE EXCEPTION 'Khong du kho VAT cho SP #% (VAT %): Can %, Ton %',
        v_product_id, v_vat_rate, v_qty_base, COALESCE(v_current_balance, 0);
    END IF;

    -- [FIX lỗi A] Trừ GIÁ TRỊ tồn theo giá vốn BÌNH QUÂN GIA QUYỀN.
    -- giá vốn đơn vị = total_value_balance / quantity_balance (trước khi trừ).
    -- Xuất hết (v_qty_base = v_current_balance) => giá trị tồn về 0, hết "tiền ảo".
    IF v_current_balance > 0 THEN
      v_value_deduct := v_current_value * (v_qty_base / v_current_balance);
    ELSE
      v_value_deduct := 0;
    END IF;

    -- Deduct (cả số lượng và giá trị)
    UPDATE public.vat_inventory_ledger
    SET quantity_balance    = quantity_balance - v_qty_base,
        total_value_balance = GREATEST(total_value_balance - v_value_deduct, 0),
        updated_at = NOW()
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate;
  END LOOP;
END;
$function$
