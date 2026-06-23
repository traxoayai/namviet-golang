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
    v_invoice_id := (p_invoice_data->>'id')::bigint;

    IF v_invoice_id IS NULL THEN
        -- Check existing invoice using all 3 fields, handling NULLs gracefully
        IF EXISTS (
            SELECT 1 FROM public.finance_invoices
            WHERE 
              NULLIF(invoice_number, '') = NULLIF(p_invoice_data->>'invoice_number', '')
              AND NULLIF(invoice_symbol, '') = NULLIF(p_invoice_data->>'invoice_symbol', '')
              AND (
                  (p_invoice_data->>'supplier_id' IS NOT NULL AND supplier_id = (p_invoice_data->>'supplier_id')::bigint)
                  OR (p_invoice_data->>'supplier_tax_code' IS NOT NULL AND supplier_tax_code = p_invoice_data->>'supplier_tax_code')
              )
              AND status != 'rejected'
        ) THEN
            RAISE EXCEPTION 'Hóa đơn số % ký hiệu % của nhà cung cấp này đã tồn tại trong hệ thống!', 
                p_invoice_data->>'invoice_number', p_invoice_data->>'invoice_symbol';
        END IF;

        -- Insert mới
        INSERT INTO public.finance_invoices (
            invoice_number, invoice_symbol, invoice_date, 
            supplier_name_raw, supplier_tax_code, supplier_id,
            total_amount_pre_tax, tax_amount, total_amount_post_tax,
            total_price_excludes_vat, total_trade_discount, total_fee_amount,
            parsed_data, file_url, file_type, status, items_json
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
            p_items_data
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
    IF p_items_data IS NOT NULL AND jsonb_typeof(p_items_data) = 'array' THEN
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
                v_item->>'name', -- Chú ý: frontend gửi là 'name'
                v_item->>'xml_unit', -- Chú ý: frontend gửi là 'xml_unit' hoặc 'internal_unit'
                v_item->>'supplier_sku',
                COALESCE((v_item->>'quantity')::numeric, 0),
                COALESCE((v_item->>'unit_price')::numeric, 0), 
                COALESCE((v_item->>'discount_rate')::numeric, 0), -- frontend gửi là 'discount_rate'
                COALESCE((v_item->>'discount_amount')::numeric, 0),
                COALESCE((v_item->>'vat_rate')::numeric, 0),
                COALESCE((v_item->>'tax_amount')::numeric, 0), 
                COALESCE((v_item->>'amount_before_tax')::numeric, 0) 
            );
        END LOOP;
    END IF;

    RETURN v_invoice_id;
END;
$function$;
