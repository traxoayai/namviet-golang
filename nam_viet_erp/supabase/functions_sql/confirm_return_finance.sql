CREATE OR REPLACE FUNCTION public.confirm_return_finance(p_return_id uuid, p_fund_account_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_return RECORD; 
    v_order RECORD; 
    v_trans_code TEXT;
BEGIN
    SELECT * INTO v_return FROM public.sales_returns WHERE id = p_return_id FOR UPDATE;
    IF v_return.status != 'PENDING_REFUND' THEN RAISE EXCEPTION 'Phiếu trả này chưa nhập kho xong hoặc đã hoàn tiền.'; END IF;

    SELECT * INTO v_order FROM public.orders WHERE id = v_return.order_id;

    IF v_return.total_refund_amount > 0 THEN
        v_trans_code := public._gen_finance_tx_code('PC');
        INSERT INTO public.finance_transactions (
            code, flow, business_type, amount, fund_account_id, partner_type, partner_id, partner_name_cache, ref_type, ref_id, description, status, created_by
        ) VALUES (
            v_trans_code, 'out', 'other', v_return.total_refund_amount, p_fund_account_id, 
            CASE WHEN v_order.customer_id IS NOT NULL THEN 'customer_b2b' ELSE 'customer' END, 
            COALESCE(v_order.customer_id, v_order.customer_b2c_id)::TEXT, 'Khách hàng trả hàng', 'sales_return', v_return.code, 
            'Hoàn tiền trả hàng (Đơn ' || v_order.code || ')', 'completed', auth.uid()
        );
    END IF;

    UPDATE public.sales_returns SET status = 'COMPLETED', updated_at = NOW() WHERE id = p_return_id;
    RETURN jsonb_build_object('success', true, 'message', 'Đã hoàn tiền và khép kín quy trình!');
END;
$function$
