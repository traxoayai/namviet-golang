CREATE OR REPLACE FUNCTION public.deduct_vat_for_pos_export(p_product_id bigint, p_vat_rate numeric, p_base_qty numeric)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_current_balance NUMERIC;
BEGIN
  SELECT quantity_balance INTO v_current_balance
  FROM public.vat_inventory_ledger
  WHERE product_id = p_product_id AND vat_rate = p_vat_rate
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Không tìm thấy kho VAT cho SP #% (VAT %)', p_product_id, p_vat_rate;
  END IF;

  IF v_current_balance < p_base_qty THEN
    RAISE EXCEPTION 'Không đủ kho VAT cho SP #%. Cần: %, Tồn: %',
      p_product_id, p_base_qty, v_current_balance;
  END IF;

  UPDATE public.vat_inventory_ledger
  SET quantity_balance = quantity_balance - p_base_qty,
      updated_at = NOW()
  WHERE product_id = p_product_id AND vat_rate = p_vat_rate;
END;
$function$
