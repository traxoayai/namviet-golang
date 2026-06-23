CREATE OR REPLACE FUNCTION public.confirm_order_payment(p_order_ids bigint[], p_fund_account_id integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_order RECORD;
    v_count INT := 0;
    v_total_receipt NUMERIC := 0;
    v_remaining_amount NUMERIC;
    v_trans_code TEXT;
    v_partner_name TEXT;
    v_fund_name TEXT;
BEGIN
    -- Validate Quỹ
    SELECT name INTO v_fund_name FROM public.fund_accounts WHERE id = p_fund_account_id;
    IF v_fund_name IS NULL THEN
        RAISE EXCEPTION 'Tài khoản quỹ không tồn tại (ID: %).', p_fund_account_id;
    END IF;

    -- Duyệt đơn hàng
    FOR v_order IN 
        SELECT o.*, c.name as customer_name
        FROM public.orders o
        LEFT JOIN public.customers_b2b c ON o.customer_id = c.id
        WHERE o.id = ANY(p_order_ids) 
          AND o.status NOT IN ('DRAFT', 'CANCELLED')
          AND o.payment_status != 'paid' 
    LOOP
        v_remaining_amount := v_order.final_amount - COALESCE(v_order.paid_amount, 0);

        IF v_remaining_amount > 0 THEN
            
            -- A. Update Đơn hàng: Đã thanh toán
            UPDATE public.orders
            SET 
                paid_amount = final_amount,
                payment_status = 'paid',
                updated_at = NOW()
            WHERE id = v_order.id;

            -- B. Tạo Phiếu Thu
            v_trans_code := public._gen_finance_tx_code('PT');
            v_partner_name := COALESCE(v_order.customer_name, 'Khách B2B');

            INSERT INTO public.finance_transactions (
                code, transaction_date, flow, business_type, amount, fund_account_id,
                partner_type, partner_id, partner_name_cache,
                ref_type, ref_id, description, created_by, status
            ) VALUES (
                v_trans_code, NOW(), 'in', 'trade', v_remaining_amount, p_fund_account_id,
                'customer_b2b', v_order.customer_id::TEXT, v_partner_name,
                'order', v_order.id::TEXT, 
                'Thu tiền đơn hàng ' || v_order.code,
                auth.uid(), 'completed'
            );

            v_count := v_count + 1;
            v_total_receipt := v_total_receipt + v_remaining_amount;
        END IF;
    END LOOP;

    RETURN jsonb_build_object(
        'success', true, 
        'count', v_count, 
        'total_amount', v_total_receipt,
        'message', 'Đã thu ' || v_total_receipt || ' vào quỹ ' || v_fund_name
    );
END;
$function$
