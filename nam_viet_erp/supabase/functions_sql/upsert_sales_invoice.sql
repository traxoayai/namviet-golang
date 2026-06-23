CREATE OR REPLACE FUNCTION public.upsert_sales_invoice(p_invoice_data jsonb, p_items_data jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_invoice_id bigint;
    v_item jsonb;
BEGIN
    v_invoice_id := (p_invoice_data->>'id')::bigint;

    IF v_invoice_id IS NULL THEN
        -- Check existing invoice
        IF EXISTS (
            SELECT 1 FROM public.sales_invoices
            WHERE 
              NULLIF(invoice_number, '') = NULLIF(p_invoice_data->>'invoice_number', '')
              AND NULLIF(invoice_serial, '') = NULLIF(p_invoice_data->>'invoice_symbol', '')
              AND (
                  (p_invoice_data->>'buyer_tax_code' IS NOT NULL AND buyer_tax_code = p_invoice_data->>'buyer_tax_code')
              )
              AND status != 'rejected'
        ) THEN
            RAISE EXCEPTION 'Hóa đơn số % ký hiệu % của khách hàng này đã tồn tại trong hệ thống!', 
                p_invoice_data->>'invoice_number', p_invoice_data->>'invoice_symbol';
        END IF;

        -- Insert mới
        INSERT INTO public.sales_invoices (
            invoice_number, invoice_serial, invoice_date, 
            buyer_name, buyer_tax_code, buyer_company_name,
            total_amount_pre_tax, vat_amount, final_amount,
            parsed_data, file_url, file_type, status, direction, items_json,
            order_id
        )
        VALUES (
            p_invoice_data->>'invoice_number',
            p_invoice_data->>'invoice_symbol',
            (p_invoice_data->>'invoice_date')::date,
            p_invoice_data->>'buyer_name',
            p_invoice_data->>'buyer_tax_code',
            p_invoice_data->>'buyer_company_name',
            (p_invoice_data->>'total_amount_pre_tax')::numeric,
            (p_invoice_data->>'tax_amount')::numeric,
            (p_invoice_data->>'total_amount_post_tax')::numeric,
            p_invoice_data->'parsed_data',
            p_invoice_data->>'file_url',
            p_invoice_data->>'file_type',
            COALESCE(p_invoice_data->>'status', 'draft'),
            COALESCE(p_invoice_data->>'direction', 'outbound'),
            p_items_data,
            NULLIF(p_invoice_data->>'order_id', '')::uuid
        )
        RETURNING id INTO v_invoice_id;
    ELSE
        -- Update
        UPDATE public.sales_invoices SET
            invoice_number = p_invoice_data->>'invoice_number',
            invoice_serial = p_invoice_data->>'invoice_symbol',
            invoice_date = (p_invoice_data->>'invoice_date')::date,
            buyer_name = p_invoice_data->>'buyer_name',
            buyer_tax_code = p_invoice_data->>'buyer_tax_code',
            buyer_company_name = p_invoice_data->>'buyer_company_name',
            total_amount_pre_tax = (p_invoice_data->>'total_amount_pre_tax')::numeric,
            vat_amount = (p_invoice_data->>'tax_amount')::numeric,
            final_amount = (p_invoice_data->>'total_amount_post_tax')::numeric,
            parsed_data = p_invoice_data->'parsed_data',
            status = COALESCE(p_invoice_data->>'status', status),
            direction = COALESCE(p_invoice_data->>'direction', direction),
            items_json = p_items_data,
            order_id = COALESCE(NULLIF(p_invoice_data->>'order_id', '')::uuid, order_id)
        WHERE id = v_invoice_id;
    END IF;

    -- XÓA TẤT CẢ ITEMS CŨ CỦA INVOICE NÀY TRONG BẢNG sales_invoice_items 
    -- Tuy nhiên hiện tại system chưa có bảng sales_invoice_items, 
    -- tạm thời không cần bảng con này vì items_json đã lưu dữ liệu chi tiết ở bảng sales_invoices.
    -- (Trong hóa đơn mua vào thì có finance_invoice_items vì để map product_id nhập kho)

    RETURN v_invoice_id;
END;
$function$
