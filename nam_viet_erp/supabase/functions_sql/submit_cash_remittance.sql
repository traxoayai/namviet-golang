CREATE OR REPLACE FUNCTION public.submit_cash_remittance(p_order_ids uuid[], p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_total_amount NUMERIC;
        v_updated_count INT;
        v_transaction_id BIGINT;
        v_trans_code TEXT;
        v_user_name TEXT;
    BEGIN
        -- 1. Tính tổng tiền hợp lệ (Chỉ lấy đơn tiền mặt & chưa nộp)
        SELECT COALESCE(SUM(final_amount), 0)
        INTO v_total_amount
        FROM public.orders
        WHERE id = ANY(p_order_ids)
          AND remittance_status = 'pending' -- Đang giữ tiền
          AND payment_method = 'cash';      -- Chỉ nộp tiền mặt

        -- Nếu không có tiền để nộp (do chọn sai hoặc đã nộp rồi)
        IF v_total_amount <= 0 THEN
            RETURN jsonb_build_object(
                'success', false,
                'message', 'Không có đơn hàng tiền mặt hợp lệ để nộp.'
            );
        END IF;

        -- 2. Lấy tên người nộp để ghi chú
        SELECT COALESCE(full_name, email) INTO v_user_name 
        FROM public.users WHERE id = p_user_id;

        -- 3. TẠO PHIẾU THU (Trạng thái PENDING - Chờ thủ quỹ duyệt)
        -- Sinh mã phiếu thu
        v_trans_code := public._gen_finance_tx_code('PT');

        INSERT INTO public.finance_transactions (
            code,
            flow,           -- 'in' (Thu tiền)
            business_type,  -- 'trade' (Bán hàng)
            amount,
            fund_account_id, -- Tạm thời để 1 (Tiền mặt), Thủ quỹ có thể sửa khi duyệt
            status,         -- 'pending' (Chờ duyệt)
            description,
            created_by,
            created_at,
            partner_type,   -- 'employee' (Nộp nội bộ)
            partner_id,
            partner_name_cache
        )
        VALUES (
            v_trans_code,
            'in',
            'trade',
            v_total_amount,
            1,              -- Hardcode ID quỹ mặc định (hoặc lấy từ config)
            'pending',
            'Nộp tiền doanh thu POS - ' || COALESCE(v_user_name, 'Sales'),
            p_user_id,
            NOW(),
            'employee',
            p_user_id::TEXT,
            v_user_name
        )
        RETURNING id INTO v_transaction_id;

        -- 4. CẬP NHẬT ĐƠN HÀNG (Gán ID phiếu thu vào đơn)
        UPDATE public.orders
        SET 
            remittance_status = 'confirming', -- Chuyển sang chờ duyệt
            remittance_transaction_id = v_transaction_id, -- Liên kết với phiếu thu vừa tạo
            updated_at = NOW()
        WHERE id = ANY(p_order_ids)
          AND remittance_status = 'pending'
          AND payment_method = 'cash';

        GET DIAGNOSTICS v_updated_count = ROW_COUNT;

        -- 5. Trả về kết quả
        RETURN jsonb_build_object(
            'success', true,
            'updated_count', v_updated_count,
            'total_amount', v_total_amount,
            'transaction_code', v_trans_code
        );
    END;
    $function$
