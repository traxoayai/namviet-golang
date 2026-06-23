CREATE OR REPLACE FUNCTION public.send_prescription_to_pos(p_appointment_id uuid, p_customer_id bigint, p_items jsonb, p_pharmacy_warehouse_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_order_id UUID;
    v_order_code TEXT;
    v_item JSONB;
    v_visit_id UUID;
    v_total_amount NUMERIC := 0;
    v_unit_price NUMERIC;
    v_conversion_rate INT;
    v_qty NUMERIC;
BEGIN
    -- 1. Tìm hoặc tạo ngầm Medical Visit
    SELECT id INTO v_visit_id FROM public.medical_visits WHERE appointment_id = p_appointment_id LIMIT 1;
    IF v_visit_id IS NULL THEN
        INSERT INTO public.medical_visits (appointment_id, customer_id, doctor_id, status)
        VALUES (p_appointment_id, p_customer_id, auth.uid(), 'in_progress') RETURNING id INTO v_visit_id;
    END IF;

    -- 2. Tạo Đơn hàng POS Nháp
    v_order_code := public._gen_finance_tx_code('RX');
    INSERT INTO public.orders (
        code, customer_b2c_id, creator_id, order_type, status, warehouse_id,
        note, payment_status, total_amount, final_amount
    ) VALUES (
        v_order_code, p_customer_id, auth.uid(), 'POS', 'DRAFT', p_pharmacy_warehouse_id,
        'Đơn thuốc từ phòng khám (Lịch hẹn: ' || p_appointment_id || ')', 'unpaid', 0, 0
    ) RETURNING id INTO v_order_id;

    -- 3. Xử lý Đơn thuốc (Order Items) & Tính Tiền chuẩn
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_qty := (v_item->>'quantity')::NUMERIC;
        
        -- Lấy giá và tỷ lệ quy đổi từ DB (Không tin tưởng FE)
        SELECT price_sell, conversion_rate 
        INTO v_unit_price, v_conversion_rate
        FROM public.product_units 
        WHERE product_id = (v_item->>'product_id')::BIGINT 
          AND unit_name = v_item->>'unit_name' 
        LIMIT 1;

        v_unit_price := COALESCE(v_unit_price, 0);
        v_conversion_rate := COALESCE(v_conversion_rate, 1);

        IF v_qty > 0 THEN
            INSERT INTO public.order_items (
                order_id, product_id, quantity, uom, unit_price, conversion_factor
            ) VALUES (
                v_order_id, (v_item->>'product_id')::BIGINT, v_qty, 
                v_item->>'unit_name', v_unit_price, v_conversion_rate
            );

            v_total_amount := v_total_amount + (v_qty * v_unit_price);
        END IF;
    END LOOP;

    -- 4. Cập nhật lại tổng tiền cho Đơn Hàng
    UPDATE public.orders 
    SET total_amount = v_total_amount, final_amount = v_total_amount
    WHERE id = v_order_id;

    RETURN jsonb_build_object('success', true, 'pos_order_id', v_order_id, 'total_amount', v_total_amount);
END;
$function$
