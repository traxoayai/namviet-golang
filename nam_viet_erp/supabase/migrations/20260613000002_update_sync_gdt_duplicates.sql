CREATE OR REPLACE FUNCTION public.sync_gdt_invoices(p_invoices jsonb)
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_inv jsonb;
    v_count integer := 0;
    v_invoice_num text;
    v_invoice_symbol text;
    v_supplier_tax_code text;
    v_buyer_tax_code text;
    v_direction text;
    v_matched_order_id uuid := NULL;
    v_matched_po_id bigint := NULL;
    v_new_invoice_id bigint;
    v_item jsonb;
    v_header jsonb;
    v_items_array jsonb;
BEGIN
    FOR v_inv IN SELECT * FROM jsonb_array_elements(p_invoices)
    LOOP
        v_header := v_inv->'header';
        v_items_array := v_inv->'items';
        v_direction := COALESCE(v_inv->>'direction', 'inbound');
        
        v_invoice_num := v_header->>'invoice_number';
        v_invoice_symbol := v_header->>'invoice_symbol';
        v_supplier_tax_code := v_header->>'supplier_tax_code';
        v_buyer_tax_code := v_header->>'buyer_tax_code';
        
        v_matched_order_id := NULL;
        v_matched_po_id := NULL;
        v_new_invoice_id := NULL;

        IF v_direction = 'inbound' THEN
            IF NOT EXISTS (
                SELECT 1 FROM finance_invoices 
                WHERE invoice_number = v_invoice_num 
                  AND COALESCE(invoice_symbol, '') = COALESCE(v_invoice_symbol, '')
                  AND COALESCE(supplier_tax_code, '') = COALESCE(v_supplier_tax_code, '')
                  AND direction = 'inbound'
            ) THEN
                -- Try to auto map purchase_orders
                SELECT po.id INTO v_matched_po_id
                FROM purchase_orders po
                JOIN suppliers s ON po.supplier_id = s.id
                WHERE s.tax_code = v_supplier_tax_code
                  AND ABS(po.total_amount - (v_header->>'total_amount_post_tax')::numeric) <= 10000
                ORDER BY po.created_at DESC
                LIMIT 1;

                INSERT INTO finance_invoices (
                    invoice_number, invoice_symbol, invoice_date,
                    supplier_name_raw, supplier_tax_code, buyer_tax_code,
                    total_amount_pre_tax, tax_amount, total_amount_post_tax,
                    parsed_data, status, direction, purchase_order_id
                ) VALUES (
                    v_invoice_num,
                    v_invoice_symbol,
                    NULLIF(v_header->>'invoice_date', '')::date,
                    v_header->>'supplier_name',
                    v_supplier_tax_code,
                    v_buyer_tax_code,
                    (v_header->>'total_amount_pre_tax')::numeric,
                    (v_header->>'total_tax')::numeric,
                    (v_header->>'total_amount_post_tax')::numeric,
                    v_inv,
                    'draft',
                    'inbound',
                    v_matched_po_id
                ) RETURNING id INTO v_new_invoice_id;
                v_count := v_count + 1;
            END IF;
        ELSE
            IF NOT EXISTS (
                SELECT 1 FROM finance_invoices 
                WHERE invoice_number = v_invoice_num 
                  AND COALESCE(invoice_symbol, '') = COALESCE(v_invoice_symbol, '')
                  AND direction = 'outbound'
            ) THEN
                -- Try to auto map orders
                SELECT o.id INTO v_matched_order_id
                FROM orders o
                JOIN customers c ON o.customer_id = c.id
                WHERE c.tax_code = v_buyer_tax_code
                  AND ABS(o.total_amount - (v_header->>'total_amount_post_tax')::numeric) <= 10000
                ORDER BY o.created_at DESC
                LIMIT 1;

                INSERT INTO finance_invoices (
                    invoice_number, invoice_symbol, invoice_date,
                    buyer_name, buyer_tax_code, buyer_company_name,
                    supplier_tax_code,
                    total_amount_pre_tax, tax_amount, total_amount_post_tax,
                    parsed_data, status, direction, order_id
                ) VALUES (
                    v_invoice_num,
                    v_invoice_symbol,
                    NULLIF(v_header->>'invoice_date', '')::date,
                    v_header->>'buyer_name',
                    v_buyer_tax_code,
                    v_header->>'buyer_name',
                    v_supplier_tax_code,
                    (v_header->>'total_amount_pre_tax')::numeric,
                    (v_header->>'total_tax')::numeric,
                    (v_header->>'total_amount_post_tax')::numeric,
                    v_inv,
                    'draft',
                    'outbound',
                    v_matched_order_id
                ) RETURNING id INTO v_new_invoice_id;
                v_count := v_count + 1;
            END IF;
        END IF;

        -- Insert Items if invoice was just created
        IF v_new_invoice_id IS NOT NULL AND jsonb_array_length(v_items_array) > 0 THEN
            FOR v_item IN SELECT * FROM jsonb_array_elements(v_items_array)
            LOOP
                INSERT INTO finance_invoice_items (
                    invoice_id,
                    vendor_product_name,
                    supplier_sku,
                    vendor_unit,
                    quantity,
                    pre_vat_price,
                    discount_percentage,
                    discount_amount,
                    vat_rate,
                    vat_amount,
                    total_amount_pre_vat
                ) VALUES (
                    v_new_invoice_id,
                    v_item->>'name',
                    v_item->>'supplier_sku',
                    v_item->>'unit',
                    COALESCE((v_item->>'quantity')::numeric, 0),
                    COALESCE((v_item->>'unit_price')::numeric, 0),
                    COALESCE((v_item->>'discount_percentage')::numeric, 0),
                    COALESCE((v_item->>'discount')::numeric, 0),
                    COALESCE((v_item->>'vat_rate')::numeric, 0),
                    COALESCE((v_item->>'total')::numeric, 0) * (COALESCE((v_item->>'vat_rate')::numeric, 0) / 100.0),
                    COALESCE((v_item->>'total')::numeric, 0)
                );
            END LOOP;
        END IF;

    END LOOP;

    RETURN v_count;
END;
$function$;
