-- Migration: Add VAT invoice tracking fields and fix VAT ledger logic
-- 1. Bổ sung các cột thông tin hóa đơn (Theo VAS)
ALTER TABLE public.finance_invoices ADD COLUMN IF NOT EXISTS total_price_excludes_VAT numeric DEFAULT 0;
ALTER TABLE public.finance_invoices ADD COLUMN IF NOT EXISTS total_trade_discount numeric DEFAULT 0;
ALTER TABLE public.finance_invoices ADD COLUMN IF NOT EXISTS total_fee_amount numeric DEFAULT 0;

-- 2. Nâng cấp logic NHẬP KHO VAT (process_vat_invoice_entry)
CREATE OR REPLACE FUNCTION public.process_vat_invoice_entry(p_invoice_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET "search_path" TO 'public'
AS $fn$
DECLARE
    v_invoice_record RECORD;
    v_item JSONB;
    v_product_id BIGINT;
    v_unit_name TEXT;
    v_qty_input NUMERIC;
    v_vat_rate NUMERIC;
    v_unit_price NUMERIC;
    v_amount_before_tax NUMERIC;
    v_conversion_rate NUMERIC;
    v_qty_base NUMERIC;
    v_total_value NUMERIC;
    v_proportional_fee NUMERIC;
    v_total_invoice_fee NUMERIC;
    v_total_price_excludes_VAT NUMERIC;
BEGIN
    SELECT * INTO v_invoice_record FROM public.finance_invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hoa don ID % khong ton tai', p_invoice_id; END IF;

    v_total_invoice_fee := COALESCE(v_invoice_record.total_fee_amount, 0);
    v_total_price_excludes_VAT := COALESCE(v_invoice_record.total_price_excludes_VAT, 0);

    FOR v_item IN SELECT * FROM jsonb_array_elements(v_invoice_record.items_json)
    LOOP
        v_product_id := (v_item->>'product_id')::BIGINT;
        v_unit_name := COALESCE(NULLIF(TRIM(v_item->>'internal_unit'), ''), NULLIF(TRIM(v_item->>'unit'), ''));
        v_qty_input := COALESCE((v_item->>'quantity')::NUMERIC, 0);
        v_vat_rate := COALESCE((v_item->>'vat_rate')::NUMERIC, 0);
        v_unit_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);
        v_amount_before_tax := COALESCE((v_item->>'amount_before_tax')::NUMERIC, v_qty_input * v_unit_price);

        IF v_product_id IS NOT NULL AND v_qty_input > 0 THEN
            
            -- [STRICT LOGIC QUY ĐỔI]
            SELECT conversion_rate INTO v_conversion_rate 
            FROM public.product_units
            WHERE product_id = v_product_id AND LOWER(unit_name) = LOWER(v_unit_name) 
            LIMIT 1;

            IF v_conversion_rate IS NULL THEN
                RAISE EXCEPTION 'Khong tim thay don vi "%" cho SP #%. Invoice #%', v_unit_name, v_product_id, p_invoice_id;
            END IF;

            -- Tính toán số lượng base
            v_qty_base := v_qty_input * v_conversion_rate;
            
            -- Phân bổ phí dựa trên Giá trị dòng / Tổng giá trị
            IF v_total_price_excludes_VAT > 0 THEN
                v_proportional_fee := ROUND((v_amount_before_tax / v_total_price_excludes_VAT) * v_total_invoice_fee, 2);
            ELSE
                v_proportional_fee := 0;
            END IF;

            -- Giá trị nhập kho VAT = Thành tiền (sau chiết khấu) + Phí phân bổ
            v_total_value := v_amount_before_tax + v_proportional_fee;

            -- [UPSERT CỘNG KHO]
            INSERT INTO public.vat_inventory_ledger (
                product_id, vat_rate, quantity_balance, total_value_balance, updated_at
            )
            VALUES (
                v_product_id, v_vat_rate, v_qty_base, v_total_value, NOW()
            )
            ON CONFLICT (product_id, vat_rate) 
            DO UPDATE SET 
                quantity_balance = vat_inventory_ledger.quantity_balance + EXCLUDED.quantity_balance,
                total_value_balance = vat_inventory_ledger.total_value_balance + EXCLUDED.total_value_balance,
                updated_at = NOW();
        END IF;
    END LOOP;
END;
$fn$;

-- 3. Nâng cấp logic XUẤT KHO VAT (process_vat_export_entry) - Bình quân gia quyền
CREATE OR REPLACE FUNCTION public.process_vat_export_entry(p_invoice_id BIGINT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET "search_path" TO 'public'
AS $fn$
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
  v_current_value NUMERIC;
  v_deducted_value NUMERIC;
BEGIN
  -- 0. Permission guard
  PERFORM public.check_rpc_access('process_vat_export_entry');

  -- 1. Get invoice
  SELECT * INTO v_invoice FROM public.finance_invoices WHERE id = p_invoice_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Hoa don #% khong ton tai', p_invoice_id;
  END IF;

  -- 2. Loop through raw_items
  FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_invoice.raw_items, '[]'::JSONB))
  LOOP
    v_qty_input := COALESCE((v_item->>'quantity')::NUMERIC, 0);
    IF v_qty_input <= 0 THEN CONTINUE; END IF;

    -- Strict unit validation
    v_unit_name := COALESCE(NULLIF(TRIM(v_item->>'unit'), ''), NULLIF(TRIM(v_item->>'internal_unit'), ''));
    IF v_unit_name IS NULL THEN
      RAISE EXCEPTION 'Item thieu don vi tinh (unit). Invoice #%', p_invoice_id;
    END IF;

    v_vat_rate := COALESCE((v_item->>'vat_rate')::NUMERIC, 0);
    v_product_id := (v_item->>'product_id')::BIGINT;
    IF v_product_id IS NULL THEN
      RAISE EXCEPTION 'Item thieu product_id. Invoice #%, item: %', p_invoice_id, v_item->>'product_name';
    END IF;

    -- Find conversion rate
    SELECT conversion_rate INTO v_conversion_rate
    FROM public.product_units
    WHERE product_id = v_product_id AND LOWER(unit_name) = LOWER(v_unit_name)
    LIMIT 1;
    
    IF v_conversion_rate IS NULL THEN
      RAISE EXCEPTION 'Khong tim thay don vi "%" cho SP #%. Invoice #%', v_unit_name, v_product_id, p_invoice_id;
    END IF;

    v_qty_base := v_qty_input * v_conversion_rate;

    -- Check VAT inventory (with FOR UPDATE lock)
    SELECT quantity_balance, total_value_balance INTO v_current_balance, v_current_value
    FROM public.vat_inventory_ledger
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate
    FOR UPDATE;

    IF NOT FOUND OR v_current_balance < v_qty_base THEN
      RAISE EXCEPTION 'Khong du kho VAT cho SP #% (VAT %): Can %, Ton %', v_product_id, v_vat_rate, v_qty_base, COALESCE(v_current_balance, 0);
    END IF;

    -- Phương pháp tính giá xuất kho: Bình quân gia quyền
    IF v_current_balance = v_qty_base THEN
      -- Nếu xuất hết kho, trừ toàn bộ giá trị (tránh lẻ thập phân)
      v_deducted_value := v_current_value;
    ELSE
      -- v_qty_base / v_current_balance * v_current_value
      v_deducted_value := ROUND((v_qty_base / v_current_balance) * v_current_value, 2);
    END IF;

    -- Deduct
    UPDATE public.vat_inventory_ledger
    SET quantity_balance = quantity_balance - v_qty_base,
        total_value_balance = total_value_balance - v_deducted_value,
        updated_at = NOW()
    WHERE product_id = v_product_id AND vat_rate = v_vat_rate;
  END LOOP;
END;
$fn$;
