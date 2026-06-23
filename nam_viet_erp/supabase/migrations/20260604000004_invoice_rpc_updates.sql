-- 1. Hàm get_mapped_product mới (Có Fuzzy Search)
DROP FUNCTION IF EXISTS public.get_mapped_product(text, text, text);
DROP FUNCTION IF EXISTS public.get_mapped_product(text, text, text, text);

CREATE OR REPLACE FUNCTION public.get_mapped_product(
    p_tax_code text, 
    p_product_name text, 
    p_vendor_unit text,
    p_supplier_sku text DEFAULT NULL
)
 RETURNS TABLE(internal_product_id bigint, internal_unit text, internal_product_unit_id bigint, conversion_rate numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_internal_id bigint;
    v_internal_unit text;
    v_internal_unit_id bigint;
    v_conversion_rate numeric;
BEGIN
    -- LUỒNG A: Tìm bằng vendor_tax_code + supplier_sku
    IF p_supplier_sku IS NOT NULL AND p_supplier_sku != '' THEN
        SELECT 
            v.internal_product_id,
            v.internal_unit,
            v.internal_product_unit_id,
            COALESCE(pu.conversion_rate, 1::numeric)
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.vendor_product_mappings v
        LEFT JOIN public.product_units pu ON v.internal_product_unit_id = pu.id
        WHERE v.vendor_tax_code = p_tax_code 
          AND v.supplier_sku = p_supplier_sku
        LIMIT 1;
    END IF;

    -- LUỒNG B: Tìm bằng vendor_tax_code + vendor_product_name (Nếu Luồng A thất bại)
    IF v_internal_id IS NULL THEN
        SELECT 
            v.internal_product_id,
            v.internal_unit,
            v.internal_product_unit_id,
            COALESCE(pu.conversion_rate, 1::numeric)
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.vendor_product_mappings v
        LEFT JOIN public.product_units pu ON v.internal_product_unit_id = pu.id
        WHERE v.vendor_tax_code = p_tax_code 
          AND v.vendor_product_name = p_product_name 
          AND (v.vendor_unit = p_vendor_unit OR (v.vendor_unit IS NULL AND p_vendor_unit = ''))
        LIMIT 1;
    END IF;

    -- LUỒNG C: Fuzzy Match qua bảng products (Nếu Luồng B thất bại)
    IF v_internal_id IS NULL AND p_product_name IS NOT NULL AND p_product_name != '' THEN
        SELECT 
            p.id,
            pu.unit_name,
            pu.id,
            pu.conversion_rate
        INTO v_internal_id, v_internal_unit, v_internal_unit_id, v_conversion_rate
        FROM public.products p
        LEFT JOIN public.product_units pu ON p.id = pu.product_id AND pu.unit_type = 'wholesale'
        WHERE p.status = 'active'
        ORDER BY similarity(unaccent(lower(p.name)), unaccent(lower(p_product_name))) DESC
        LIMIT 1;
        -- Ghi chú: Có thể thêm điều kiện sim_score >= 0.3 nếu muốn chặt chẽ hơn.
    END IF;

    -- TRẢ VỀ KẾT QUẢ
    IF v_internal_id IS NOT NULL THEN
        RETURN QUERY SELECT v_internal_id, v_internal_unit, v_internal_unit_id, COALESCE(v_conversion_rate, 1::numeric);
    END IF;
END;
$function$;

-- 2. Hàm upsert_finance_invoice (Lưu cả Invoices và Invoice Items một cách đồng bộ)
CREATE OR REPLACE FUNCTION public.upsert_finance_invoice(
    p_invoice_data jsonb,
    p_items_data jsonb
)
RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_invoice_id bigint;
    v_item jsonb;
BEGIN
    -- UPSERT bảng finance_invoices (Dùng JSON để linh hoạt)
    -- Giả sử JSON gửi lên là hợp lệ (có id nếu update, không có id nếu insert)
    v_invoice_id := (p_invoice_data->>'id')::bigint;

    IF v_invoice_id IS NULL THEN
        -- Insert mới
        INSERT INTO public.finance_invoices (
            invoice_number, invoice_symbol, invoice_date, 
            supplier_name_raw, supplier_tax_code, supplier_id,
            total_amount_pre_tax, tax_amount, total_amount_post_tax,
            total_price_excludes_vat, total_trade_discount, total_fee_amount,
            parsed_data, file_url, file_type, status,
            items_json -- Giữ lại items_json để tương thích tạm thời
        )
        VALUES (
            p_invoice_data->>'invoice_number',
            p_invoice_data->>'invoice_symbol',
            (p_invoice_data->>'invoice_date')::date,
            p_invoice_data->>'supplier_name_raw',
            p_invoice_data->>'supplier_tax_code',
            (p_invoice_data->>'supplier_id')::bigint,
            (p_invoice_data->>'total_amount_pre_tax')::numeric,
            (p_invoice_data->>'tax_amount')::numeric,
            (p_invoice_data->>'total_amount_post_tax')::numeric,
            (p_invoice_data->>'total_price_excludes_vat')::numeric,
            (p_invoice_data->>'total_trade_discount')::numeric,
            (p_invoice_data->>'total_fee_amount')::numeric,
            p_invoice_data->'parsed_data',
            p_invoice_data->>'file_url',
            p_invoice_data->>'file_type',
            COALESCE(p_invoice_data->>'status', 'draft'),
            p_items_data -- Lưu nguyên gốc để backup
        )
        RETURNING id INTO v_invoice_id;
    ELSE
        -- Update
        UPDATE public.finance_invoices SET
            invoice_number = p_invoice_data->>'invoice_number',
            invoice_symbol = p_invoice_data->>'invoice_symbol',
            invoice_date = (p_invoice_data->>'invoice_date')::date,
            supplier_name_raw = p_invoice_data->>'supplier_name_raw',
            supplier_tax_code = p_invoice_data->>'supplier_tax_code',
            supplier_id = (p_invoice_data->>'supplier_id')::bigint,
            total_amount_pre_tax = (p_invoice_data->>'total_amount_pre_tax')::numeric,
            tax_amount = (p_invoice_data->>'tax_amount')::numeric,
            total_amount_post_tax = (p_invoice_data->>'total_amount_post_tax')::numeric,
            total_price_excludes_vat = (p_invoice_data->>'total_price_excludes_vat')::numeric,
            total_trade_discount = (p_invoice_data->>'total_trade_discount')::numeric,
            total_fee_amount = (p_invoice_data->>'total_fee_amount')::numeric,
            parsed_data = p_invoice_data->'parsed_data',
            status = COALESCE(p_invoice_data->>'status', status),
            items_json = p_items_data
        WHERE id = v_invoice_id;
    END IF;

    -- XÓA TẤT CẢ ITEMS CŨ CỦA INVOICE NÀY TRONG BẢNG finance_invoice_items
    DELETE FROM public.finance_invoice_items WHERE invoice_id = v_invoice_id;

    -- INSERT ITEMS MỚI
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items_data)
    LOOP
        INSERT INTO public.finance_invoice_items (
            invoice_id,
            product_id,
            product_unit_id,
            vendor_product_name,
            vendor_unit,
            supplier_sku,
            quantity,
            pre_vat_price,
            discount_percentage,
            discount_amount,
            vat_rate,
            vat_amount,
            total_amount_pre_vat
        )
        VALUES (
            v_invoice_id,
            (v_item->>'product_id')::bigint,
            (v_item->>'internal_product_unit_id')::bigint,
            v_item->>'product_name',
            v_item->>'unit',
            v_item->>'supplier_sku',
            (v_item->>'quantity')::numeric,
            (v_item->>'unit_price')::numeric, -- frontend gọi là unit_price, thực chất là pre_vat_price chưa ck
            (v_item->>'discount_percentage')::numeric,
            (v_item->>'discount_amount')::numeric,
            (v_item->>'vat_rate')::numeric,
            (v_item->>'tax_amount')::numeric, -- map từ tax_amount
            (v_item->>'amount_before_tax')::numeric -- map từ amount_before_tax
        );
    END LOOP;

    RETURN v_invoice_id;
END;
$function$;

-- 3. Cập nhật process_vat_invoice_entry để đọc từ finance_invoice_items
CREATE OR REPLACE FUNCTION public.process_vat_invoice_entry(p_invoice_id bigint)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET "search_path" TO 'public'
AS $fn$
DECLARE
    v_invoice_record RECORD;
    v_item RECORD;
    v_conversion_rate NUMERIC;
    v_qty_base NUMERIC;
    v_total_value NUMERIC;
    v_proportional_fee NUMERIC;
    v_total_invoice_fee NUMERIC;
    v_total_price_excludes_vat NUMERIC;
BEGIN
    SELECT * INTO v_invoice_record FROM public.finance_invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hoa don ID % khong ton tai', p_invoice_id; END IF;

    v_total_invoice_fee := COALESCE(v_invoice_record.total_fee_amount, 0);
    v_total_price_excludes_vat := COALESCE(v_invoice_record.total_price_excludes_vat, 0);

    -- Loop thông qua bảng finance_invoice_items
    FOR v_item IN SELECT * FROM public.finance_invoice_items WHERE invoice_id = p_invoice_id
    LOOP
        IF v_item.product_id IS NOT NULL AND v_item.quantity > 0 THEN
            
            -- Lấy tỷ lệ quy đổi
            SELECT conversion_rate INTO v_conversion_rate 
            FROM public.product_units
            WHERE id = v_item.product_unit_id
            LIMIT 1;

            -- Fallback nếu không truyền product_unit_id (lấy từ tên)
            IF v_conversion_rate IS NULL THEN
                SELECT pu.conversion_rate INTO v_conversion_rate 
                FROM public.product_units pu
                WHERE pu.product_id = v_item.product_id AND LOWER(pu.unit_name) = LOWER(v_item.vendor_unit) 
                LIMIT 1;
            END IF;

            IF v_conversion_rate IS NULL THEN
                RAISE EXCEPTION 'Khong tim thay don vi "%" cho SP #%. Invoice #%', v_item.vendor_unit, v_item.product_id, p_invoice_id;
            END IF;

            -- Tính toán số lượng base
            v_qty_base := v_item.quantity * v_conversion_rate;
            
            -- Phân bổ phí dựa trên Giá trị dòng / Tổng giá trị
            IF v_total_price_excludes_vat > 0 THEN
                v_proportional_fee := ROUND((v_item.total_amount_pre_vat / v_total_price_excludes_vat) * v_total_invoice_fee, 2);
            ELSE
                v_proportional_fee := 0;
            END IF;

            -- Giá trị nhập kho VAT = Thành tiền (trước thuế) + Phí phân bổ
            v_total_value := v_item.total_amount_pre_vat + v_proportional_fee;

            -- [UPSERT CỘNG KHO]
            INSERT INTO public.vat_inventory_ledger (
                product_id, vat_rate, quantity_balance, total_value_balance, updated_at
            )
            VALUES (
                v_item.product_id, v_item.vat_rate, v_qty_base, v_total_value, NOW()
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
