CREATE OR REPLACE FUNCTION public.create_purchase_order(p_supplier_id bigint, p_expected_date timestamp with time zone, p_note text, p_delivery_method text, p_shipping_partner_id bigint, p_shipping_fee numeric, p_status text, p_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_po_id BIGINT;
    v_po_code TEXT;
    v_item JSONB;
    v_total_amount NUMERIC := 0;
    
    -- Biến xử lý item
    v_qty_ordered INT;
    v_unit_price NUMERIC;
    v_is_bonus BOOLEAN;
    v_product_record RECORD;
    v_conversion_factor INT;
    v_base_qty INT;
BEGIN
    -- Sinh mã phiếu
    v_po_code := 'PO-' || to_char(NOW(), 'YYMM') || '-' || upper(substring(md5(random()::text) from 1 for 4));

    -- Insert Header
    INSERT INTO public.purchase_orders (
        code, supplier_id, expected_delivery_date, note, delivery_method, 
        shipping_partner_id, shipping_fee, status, 
        delivery_status, payment_status, creator_id, created_at, updated_at
    ) VALUES (
        v_po_code, p_supplier_id, p_expected_date, p_note, p_delivery_method, 
        p_shipping_partner_id, COALESCE(p_shipping_fee, 0), p_status, 
        'pending', 'unpaid', auth.uid(), NOW(), NOW()
    ) RETURNING id INTO v_po_id;

    -- Insert Items
    IF p_items IS NOT NULL THEN
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
        LOOP
            v_qty_ordered := COALESCE((v_item->>'quantity')::INT, (v_item->>'quantity_ordered')::INT, 0);
            v_is_bonus := COALESCE((v_item->>'is_bonus')::BOOLEAN, false);
            
            IF v_is_bonus THEN
                v_unit_price := 0;
            ELSE
                v_unit_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);
            END IF;

            IF v_qty_ordered > 0 THEN
                -- Lấy quy đổi
                SELECT items_per_carton, wholesale_unit INTO v_product_record
                FROM public.products WHERE id = (v_item->>'product_id')::BIGINT;

                -- Tính toán conversion factor
                IF (v_item->>'unit') = v_product_record.wholesale_unit THEN
                    v_conversion_factor := COALESCE(v_product_record.items_per_carton, 1);
                ELSE
                    v_conversion_factor := 1;
                END IF;
                v_base_qty := v_qty_ordered * v_conversion_factor;

                -- Insert Item
                INSERT INTO public.purchase_order_items (
                    po_id, product_id, quantity_ordered, uom_ordered, unit, 
                    unit_price, is_bonus, conversion_factor, base_quantity
                ) VALUES (
                    v_po_id, (v_item->>'product_id')::BIGINT, v_qty_ordered, 
                    (v_item->>'unit')::TEXT, (v_item->>'unit')::TEXT, 
                    v_unit_price, v_is_bonus, v_conversion_factor, v_base_qty
                );
                
                v_total_amount := v_total_amount + (v_qty_ordered * v_unit_price);
            END IF;
        END LOOP;
    END IF;

    -- Update Total
    UPDATE public.purchase_orders 
    SET total_amount = v_total_amount,
        final_amount = v_total_amount + COALESCE(p_shipping_fee, 0)
    WHERE id = v_po_id;

    RETURN jsonb_build_object('id', v_po_id, 'code', v_po_code, 'message', 'Tạo đơn thành công');
END;
$function$
