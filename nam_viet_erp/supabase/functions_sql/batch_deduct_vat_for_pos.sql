CREATE OR REPLACE FUNCTION public.batch_deduct_vat_for_pos(p_items jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_item JSONB;
  v_product_id BIGINT;
  v_vat_rate NUMERIC;
  v_qty NUMERIC;
  v_unit TEXT;
  v_conversion_rate NUMERIC;
  v_base_qty NUMERIC;
  v_current_balance NUMERIC;
BEGIN
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    v_product_id := (v_item->>'product_id')::BIGINT;
    v_vat_rate := COALESCE((v_item->>'vat_rate')::NUMERIC, 0);
    v_qty := COALESCE((v_item->>'quantity')::NUMERIC, 0);
    v_unit := COALESCE(v_item->>'unit', 'Viên');

    IF v_qty <= 0 THEN CONTINUE; END IF;

    SELECT conversion_rate INTO v_conversion_rate
    FROM public.product_units
    WHERE product_id = v_product_id AND unit_name = v_unit LIMIT 1;
    v_conversion_rate := COALESCE(v_conversion_rate, 1);
    v_base_qty := v_qty * v_conversion_rate;

    SELECT quantity_balance INTO v_current_balance
    FROM public.vat_inventory_ledger
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate
    FOR UPDATE;

    IF NOT FOUND THEN
      RAISE EXCEPTION 'Không tìm thấy kho VAT cho SP #% (VAT %)', v_product_id, v_vat_rate;
    END IF;
    IF v_current_balance < v_base_qty THEN
      RAISE EXCEPTION 'Không đủ kho VAT SP #%. Cần: %, Tồn: %', v_product_id, v_base_qty, v_current_balance;
    END IF;

    UPDATE public.vat_inventory_ledger
    SET quantity_balance = quantity_balance - v_base_qty, updated_at = NOW()
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate;
  END LOOP;
END;
$function$
