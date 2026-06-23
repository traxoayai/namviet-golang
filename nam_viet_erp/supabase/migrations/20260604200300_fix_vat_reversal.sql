-- Fix VAT inventory reversal logic for V3 Schema (Balance based)

DROP FUNCTION IF EXISTS public.reverse_vat_invoice_entry(bigint);

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
BEGIN
  -- 1. Get the invoice
  SELECT * INTO v_invoice FROM public.finance_invoices WHERE id = p_invoice_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hóa đơn #% không tồn tại', p_invoice_id;
  END IF;

  -- 2. Reverse VAT inventory ONLY if status is 'verified'
  IF v_invoice.status = 'verified' THEN
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
                  v_proportional_fee := ROUND((v_item.total_amount_pre_vat / v_total_price_excludes_vat) * v_total_invoice_fee, 2);
              ELSE
                  v_proportional_fee := 0;
              END IF;

              v_total_value := v_item.total_amount_pre_vat + v_proportional_fee;

              -- Trừ kho VAT (lỗi CHECK constraint quantity_balance >= 0 sẽ tự động rollback nếu kho âm)
              UPDATE public.vat_inventory_ledger 
              SET 
                  quantity_balance = quantity_balance - v_qty_base,
                  total_value_balance = total_value_balance - v_total_value,
                  updated_at = NOW()
              WHERE product_id = v_item.product_id AND vat_rate = v_item.vat_rate;
              
              IF NOT FOUND THEN
                  RAISE EXCEPTION 'Không tìm thấy sản phẩm #% trong kho VAT để hoàn tác.', v_item.product_id;
              END IF;
          END IF;
      END LOOP;
  END IF;
END;
$function$;


DROP FUNCTION IF EXISTS public.delete_invoice_atomic(bigint);

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
$function$;
