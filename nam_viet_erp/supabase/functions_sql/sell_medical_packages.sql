CREATE OR REPLACE FUNCTION public.sell_medical_packages(p_customer_id bigint, p_packages jsonb, p_fund_account_id bigint DEFAULT 1)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_order_id UUID;
    v_order_code TEXT;
    v_trans_code TEXT;
    v_pkg JSONB;
    v_item JSONB;
    v_total_amount NUMERIC := 0;
    v_pkg_price NUMERIC;
    v_validity_days INT;
    v_expiry_date DATE;
    v_customer_name TEXT;
BEGIN
    SELECT name INTO v_customer_name FROM public.customers WHERE id = p_customer_id;

    -- 1. Tạo Đơn hàng (Loại POS - Bán tại quầy)
    v_order_code := public._gen_finance_tx_code('PKG');
    INSERT INTO public.orders (
        code, customer_b2c_id, creator_id, order_type, status, payment_method,
        total_amount, final_amount, paid_amount, payment_status, remittance_status, note
    ) VALUES (
        v_order_code, p_customer_id, auth.uid(), 'POS', 'COMPLETED', 'cash',
        0, 0, 0, 'paid', 'pending', 'Bán Gói Dịch vụ/Khám bệnh'
    ) RETURNING id INTO v_order_id;

    -- 2. Vòng lặp bóc tách Gói (Packages)
    FOR v_pkg IN SELECT * FROM jsonb_array_elements(p_packages)
    LOOP
        v_pkg_price := (v_pkg->>'price')::NUMERIC;
        v_total_amount := v_total_amount + v_pkg_price;

        -- Lấy thời hạn gói
        SELECT validity_days INTO v_validity_days FROM public.service_packages WHERE id = (v_pkg->>'id')::BIGINT;
        IF v_validity_days IS NOT NULL THEN
            v_expiry_date := CURRENT_DATE + v_validity_days;
        ELSE
            v_expiry_date := CURRENT_DATE + 3650; -- Mặc định 10 năm nếu không set hạn
        END IF;

        -- Bóc tách từng dịch vụ con (Items) bên trong Gói để nhét vào Ví Dịch Vụ
        FOR v_item IN SELECT * FROM jsonb_array_elements(v_pkg->'service_package_items')
        LOOP
            INSERT INTO public.customer_service_wallets (
                customer_id, order_id, package_id, product_id, 
                total_quantity, used_quantity, expiry_date, status
            ) VALUES (
                p_customer_id, v_order_id, (v_pkg->>'id')::BIGINT, (v_item->>'item_id')::BIGINT,
                (v_item->>'quantity')::INT, 0, v_expiry_date, 'active'
            );
            
            -- Ghi nhận Order Items (Để kế toán biết đã bán cái gì)
            -- Phân bổ giá vốn/bán xuống item nếu cần (Ở đây bán nguyên gói nên lưu item giá 0 để track số lượng)
            INSERT INTO public.order_items (order_id, product_id, quantity, uom, unit_price, note)
            VALUES (v_order_id, (v_item->>'item_id')::BIGINT, (v_item->>'quantity')::INT, 'Lần', 0, 'Thuộc gói: ' || (v_pkg->>'name'));
        END LOOP;
    END LOOP;

    -- 3. Cập nhật Tổng tiền Hóa đơn
    UPDATE public.orders 
    SET total_amount = v_total_amount, final_amount = v_total_amount, paid_amount = v_total_amount
    WHERE id = v_order_id;

    -- 4. TẠO PHIẾU THU TÀI CHÍNH
    IF v_total_amount > 0 THEN
        v_trans_code := public._gen_finance_tx_code('PT');
        INSERT INTO public.finance_transactions (
            code, transaction_date, flow, business_type, amount, fund_account_id,
            partner_type, partner_id, partner_name_cache, ref_type, ref_id, description, status, created_by
        ) VALUES (
            v_trans_code, NOW(), 'in', 'trade', v_total_amount, p_fund_account_id,
            'customer', p_customer_id::text, COALESCE(v_customer_name, 'Khách Lẻ'), 
            'order', v_order_id::text, 'Thu tiền bán Gói Khám ' || v_order_code, 'completed', auth.uid()
        );
    END IF;

    RETURN jsonb_build_object('success', true, 'order_id', v_order_id, 'total_amount', v_total_amount);
END;
$function$
