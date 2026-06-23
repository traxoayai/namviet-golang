CREATE OR REPLACE FUNCTION public.reverse_vat_invoice_entry(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_invoice RECORD;
  v_item RECORD;
  v_conversion_rate NUMERIC;
  v_qty_base NUMERIC;
  v_total_value NUMERIC;
  v_proportional_fee NUMERIC;
  v_total_invoice_fee NUMERIC;
  v_total_price_excludes_vat NUMERIC;
  v_direction TEXT;
BEGIN
  -- 1. Get the invoice
  SELECT * INTO v_invoice FROM public.finance_invoices WHERE id = p_invoice_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hóa đơn #% không tồn tại', p_invoice_id;
  END IF;

  v_direction := COALESCE(v_invoice.direction, 'inbound');

  -- 2. Reverse VAT inventory ONLY if status indicates it has affected inventory
  IF v_invoice.status IN ('verified', 'verified_outbound', 'issued_outbound') THEN
      v_total_invoice_fee := COALESCE(v_invoice.total_fee_amount, 0);
      v_total_price_excludes_vat := COALESCE(v_invoice.total_price_excludes_vat, 0);

      FOR v_item IN SELECT * FROM public.finance_invoice_items WHERE invoice_id = p_invoice_id
      LOOP
          IF v_item.product_id IS NOT NULL AND v_item.quantity > 0 THEN
              
              -- Lấy tỷ lệ quy đổi
              SELECT conversion_rate INTO v_conversion_rate 
              FROM public.product_units
              WHERE id = v_item.product_unit_id
              LIMIT 1;

              IF v_conversion_rate IS NULL THEN
                  SELECT pu.conversion_rate INTO v_conversion_rate 
                  FROM public.product_units pu
                  WHERE pu.product_id = v_item.product_id AND LOWER(pu.unit_name) = LOWER(v_item.vendor_unit) 
                  LIMIT 1;
              END IF;
              
              v_conversion_rate := COALESCE(v_conversion_rate, 1);

              -- Tính toán số lượng base
              v_qty_base := v_item.quantity * v_conversion_rate;
              
              -- Tính toán giá trị
              IF v_total_price_excludes_vat > 0 THEN
                  v_proportional_fee := ROUND((COALESCE(v_item.total_amount_pre_vat, 0) / v_total_price_excludes_vat) * v_total_invoice_fee, 2);
              ELSE
                  v_proportional_fee := 0;
              END IF;

              v_total_value := COALESCE(v_item.total_amount_pre_vat, 0) + v_proportional_fee;

              IF v_direction = 'outbound' THEN
                  -- Hoàn tác hóa đơn Bán ra -> Trả lại hàng vào kho VAT (Cộng vào)
                  INSERT INTO public.vat_inventory_ledger (product_id, vat_rate, quantity_balance, total_value_balance, updated_at)
                  VALUES (v_item.product_id, COALESCE(v_item.vat_rate, 0), v_qty_base, v_total_value, NOW())
                  ON CONFLICT (product_id, vat_rate)
                  DO UPDATE SET
                      quantity_balance = public.vat_inventory_ledger.quantity_balance + EXCLUDED.quantity_balance,
                      total_value_balance = public.vat_inventory_ledger.total_value_balance + EXCLUDED.total_value_balance,
                      updated_at = NOW();
              ELSE
                  -- Hoàn tác hóa đơn Mua vào -> Rút lại hàng khỏi kho VAT (Trừ đi)
                  UPDATE public.vat_inventory_ledger 
                  SET 
                      quantity_balance = quantity_balance - v_qty_base,
                      total_value_balance = total_value_balance - v_total_value,
                      updated_at = NOW()
                  WHERE product_id = v_item.product_id AND vat_rate = COALESCE(v_item.vat_rate, 0);
                  
                  -- Bỏ qua theo yêu cầu (không raise Exception nếu không thấy)
              END IF;
          END IF;
      END LOOP;
  END IF;
END;
$function$;
