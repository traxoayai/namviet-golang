CREATE OR REPLACE FUNCTION public.update_purchase_order(p_po_id bigint, p_supplier_id bigint, p_expected_date timestamp with time zone, p_note text, p_items jsonb, p_delivery_method text DEFAULT 'internal'::text, p_shipping_partner_id bigint DEFAULT NULL::bigint, p_shipping_fee numeric DEFAULT 0, p_status text DEFAULT 'DRAFT'::text, p_total_packages integer DEFAULT 1, p_carrier_name text DEFAULT NULL::text, p_carrier_contact text DEFAULT NULL::text, p_carrier_phone text DEFAULT NULL::text, p_expected_delivery_time timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
    v_total_amount NUMERIC := 0;
    v_qty NUMERIC;
    v_price NUMERIC;
    v_po_status TEXT;
    v_discount_amount NUMERIC;
BEGIN
    -- Check trạng thái
    SELECT status, COALESCE(discount_amount, 0) 
    INTO v_po_status, v_discount_amount 
    FROM public.purchase_orders WHERE id = p_po_id;
    
    IF v_po_status NOT IN ('DRAFT', 'PENDING', 'REJECTED') THEN
        RAISE EXCEPTION 'Không thể sửa đơn hàng đang xử lý hoặc đã hoàn tất (Status: %).', v_po_status;
    END IF;

    -- 1. Xóa items cũ để insert lại (Sync mới hoàn toàn)
    DELETE FROM public.purchase_order_items WHERE po_id = p_po_id;

    -- 2. Insert items mới và tính tổng tiền
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := COALESCE((v_item->>'quantity')::NUMERIC, (v_item->>'quantity_ordered')::NUMERIC, 0);
        v_price := COALESCE((v_item->>'unit_price')::NUMERIC, 0);

        IF v_qty > 0 THEN
            INSERT INTO public.purchase_order_items (
                po_id, product_id, quantity_ordered, unit_price, uom_ordered, unit, created_at
            ) VALUES (
                p_po_id,
                (v_item->>'product_id')::BIGINT,
                v_qty,
                v_price,
                (v_item->>'uom')::TEXT,
                (v_item->>'uom')::TEXT, 
                NOW()
            );

            -- Cộng dồn: SL * Đơn giá
            v_total_amount := v_total_amount + (v_qty * v_price);
        END IF;
    END LOOP;

    -- 3. Update Master PO (Full Fields)
    UPDATE public.purchase_orders
    SET 
        supplier_id = p_supplier_id,
        expected_delivery_date = p_expected_date,
        note = p_note,
        delivery_method = p_delivery_method,
        shipping_partner_id = p_shipping_partner_id,
        shipping_fee = COALESCE(p_shipping_fee, 0),
        status = p_status,
        
        -- [IMPORTANT] Cập nhật tổng tiền tự động
        total_amount = v_total_amount,
        final_amount = v_total_amount + COALESCE(p_shipping_fee, 0) - v_discount_amount,
        
        -- [NEW] Logistics Fields
        total_packages = COALESCE(p_total_packages, 1),
        carrier_name = p_carrier_name,
        carrier_contact = p_carrier_contact,
        carrier_phone = p_carrier_phone,
        expected_delivery_time = p_expected_delivery_time,
        
        updated_at = NOW()
    WHERE id = p_po_id;

    RETURN TRUE;
END;
$function$
