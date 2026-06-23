CREATE OR REPLACE FUNCTION public.process_bulk_payment(p_customer_id bigint, p_total_amount numeric, p_allocations jsonb, p_fund_account_id bigint DEFAULT 1, p_description text DEFAULT 'Thanh toán gộp công nợ'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
    v_order_id UUID;
    v_alloc_amount NUMERIC;
    v_order_final NUMERIC;
    v_order_paid NUMERIC;
    v_new_paid NUMERIC;
    v_customer_name TEXT;
    v_trans_code TEXT;
    v_sum_allocated NUMERIC := 0;
BEGIN
    SELECT name INTO v_customer_name FROM public.customers_b2b WHERE id = p_customer_id;

    -- 1. Vòng lặp xử lý Đơn hàng
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_allocations)
    LOOP
        v_order_id := (v_item->>'order_id')::UUID;
        v_alloc_amount := (v_item->>'allocated_amount')::NUMERIC;
        
        IF v_alloc_amount > 0 THEN
            v_sum_allocated := v_sum_allocated + v_alloc_amount;

            SELECT final_amount, paid_amount INTO v_order_final, v_order_paid 
            FROM public.orders WHERE id = v_order_id FOR UPDATE;

            v_new_paid := COALESCE(v_order_paid, 0) + v_alloc_amount;

            -- Cập nhật đơn hàng
            UPDATE public.orders
            SET 
                paid_amount = v_new_paid,
                payment_status = CASE 
                    WHEN v_new_paid <= 0 THEN 'unpaid'
                    WHEN v_new_paid < v_order_final THEN 'partial' 
                    ELSE 'paid' 
                END,
                updated_at = NOW()
            WHERE id = v_order_id;

            -- [CORE FIX 1]: Đổi 'customer' thành 'customer_b2b'
            v_trans_code := public._gen_finance_tx_code('PT');
            INSERT INTO public.finance_transactions (
                code, transaction_date, flow, business_type, amount, fund_account_id,
                partner_type, partner_id, partner_name_cache, ref_type, ref_id, 
                description, status, created_by
            ) VALUES (
                v_trans_code, NOW(), 'in', 'trade', v_alloc_amount, p_fund_account_id,
                'customer_b2b', p_customer_id::text, v_customer_name, 'order', v_order_id::text, 
                p_description || ' (Gạch nợ đơn: ' || v_order_id || ')', 'completed', auth.uid()
            );
        END IF;
    END LOOP;

    IF v_sum_allocated > p_total_amount THEN
        RAISE EXCEPTION 'LỖI KẾ TOÁN: Số tiền gạch nợ chi tiết (%, đ) không được lớn hơn Tổng tiền thực thu (%, đ)!', v_sum_allocated, p_total_amount;
    END IF;

    -- Xử lý tiền nộp thừa (Chưa phân bổ / Tạm ứng)
    IF p_total_amount > v_sum_allocated THEN
        v_trans_code := public._gen_finance_tx_code('PT');
        INSERT INTO public.finance_transactions (
            code, transaction_date, flow, business_type, amount, fund_account_id,
            partner_type, partner_id, partner_name_cache, ref_type, ref_id, 
            description, status, created_by
        ) VALUES (
            v_trans_code, NOW(), 'in', 'trade', (p_total_amount - v_sum_allocated), p_fund_account_id,
            'customer_b2b', p_customer_id::text, v_customer_name, 'other', NULL, 
            'Tiền khách nộp thừa/Tạm ứng (Chưa phân bổ)', 'completed', auth.uid()
        );
    END IF;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã phân bổ thanh toán thành công!',
        'total_received', p_total_amount,
        'total_allocated', v_sum_allocated
    );
END;
$function$
