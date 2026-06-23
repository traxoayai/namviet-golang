CREATE OR REPLACE FUNCTION public.get_supplier_quick_info(p_supplier_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_total_purchase NUMERIC;
    v_opening_debt NUMERIC;
    v_total_paid NUMERIC;
    v_total_purchase_month NUMERIC;
BEGIN
    -- 1. Tổng giá trị mua hàng
    SELECT COALESCE(SUM(final_amount), 0) INTO v_total_purchase
    FROM public.purchase_orders
    WHERE supplier_id = p_supplier_id AND status <> 'CANCELLED';

    -- 2. Nợ đầu kỳ
    SELECT COALESCE(SUM(amount), 0) INTO v_opening_debt
    FROM public.finance_transactions
    WHERE partner_type = 'supplier' AND partner_id = p_supplier_id::TEXT AND business_type = 'opening_balance';

    -- 3. Tổng đã chi trả
    SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
    FROM public.finance_transactions
    WHERE partner_type = 'supplier' AND partner_id = p_supplier_id::TEXT AND flow = 'out' AND status = 'completed' AND business_type <> 'opening_balance';

    -- 4. Tổng mua trong tháng (KPI)
    SELECT COALESCE(SUM(final_amount), 0) INTO v_total_purchase_month
    FROM public.purchase_orders
    WHERE supplier_id = p_supplier_id AND created_at >= date_trunc('month', CURRENT_DATE);

    RETURN jsonb_build_object(
        'current_debt', (v_total_purchase + v_opening_debt) - v_total_paid, -- Công thức thông minh
        'purchased_this_month', v_total_purchase_month,
        'opening_debt', v_opening_debt
    );
END;
$function$
