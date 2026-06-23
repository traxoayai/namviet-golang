CREATE OR REPLACE FUNCTION public.checkout_clinical_services(p_appointment_id uuid, p_customer_id bigint, p_services jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_order_id UUID;
    v_order_code TEXT;
    v_item JSONB;
    v_pkg_id BIGINT;
    v_db_price NUMERIC;
    v_total_amount NUMERIC := 0;
    v_visit_id UUID;
BEGIN
    -- 1. Tìm hoặc tạo ngầm Medical Visit (Phiếu khám) nếu chưa có
    SELECT id INTO v_visit_id FROM public.medical_visits WHERE appointment_id = p_appointment_id LIMIT 1;
    IF v_visit_id IS NULL THEN
        INSERT INTO public.medical_visits (appointment_id, customer_id, doctor_id, status)
        VALUES (p_appointment_id, p_customer_id, auth.uid(), 'in_progress') RETURNING id INTO v_visit_id;
    END IF;

    -- 2. Tạo Đơn hàng CLINICAL (Nháp tiền trước)
    v_order_code := public._gen_finance_tx_code('CLI');
    INSERT INTO public.orders (
        code, customer_b2c_id, creator_id, order_type, status, payment_method,
        total_amount, final_amount, paid_amount, payment_status, remittance_status, note
    ) VALUES (
        v_order_code, p_customer_id, auth.uid(), 'CLINICAL', 'COMPLETED', 'cash',
        0, 0, 0, 'paid', 'pending', 'Thanh toán dịch vụ tại bàn (Lịch hẹn: ' || p_appointment_id || ')'
    ) RETURNING id INTO v_order_id;

    -- 3. Xử lý từng dịch vụ Frontend gửi xuống (Bảo mật: Lấy giá từ DB)
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_services)
    LOOP
        v_pkg_id := (v_item->>'id')::BIGINT;
        
        -- Lấy giá trị thực tế từ Database để chống hack/lỗi
        SELECT price INTO v_db_price FROM public.service_packages WHERE id = v_pkg_id;
        
        IF v_db_price IS NOT NULL THEN
            -- A. Tạo Request Cận lâm sàng / Tiêm chủng
            INSERT INTO public.clinical_service_requests (
                medical_visit_id, patient_id, doctor_id, service_package_id, 
                service_name_snapshot, category, status, payment_order_id, created_by
            ) VALUES (
                v_visit_id, p_customer_id, auth.uid(), v_pkg_id,
                v_item->>'name', v_item->>'clinical_category', 'processing', v_order_id, auth.uid()
            );

            -- B. Tạo Order Item
            INSERT INTO public.order_items (order_id, product_id, quantity, uom, unit_price, conversion_factor)
            VALUES (v_order_id, v_pkg_id, 1, 'Lần', v_db_price, 1);

            v_total_amount := v_total_amount + v_db_price;
        END IF;
    END LOOP;

    -- 4. Chốt Tổng tiền
    UPDATE public.orders 
    SET total_amount = v_total_amount, final_amount = v_total_amount, paid_amount = v_total_amount
    WHERE id = v_order_id;

    -- Đồng bộ trạng thái Lịch hẹn
    UPDATE public.appointments SET status = 'examining' WHERE id = p_appointment_id AND status = 'waiting';
    UPDATE public.clinical_queues SET status = 'examining' WHERE appointment_id = p_appointment_id AND status = 'waiting';

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id, 'total_amount', v_total_amount, 'message', 'Đã lưu chỉ định & thu tiền');
END;
$function$
