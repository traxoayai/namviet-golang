CREATE OR REPLACE FUNCTION public.get_partner_debt_live(p_partner_id bigint, p_partner_type text)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_total_sales numeric := 0;
    v_total_paid_via_finance numeric := 0;
BEGIN
    -- 1. TÍNH TỔNG PHẢI THU
    -- Bao gồm cả đơn bán hàng bình thường VÀ đơn nợ ảo (status = COMPLETED, order_type = opening_debt)
    SELECT COALESCE(SUM(final_amount), 0)
    INTO v_total_sales
    FROM public.orders
    WHERE status IN ('CONFIRMED', 'PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED', 'PARTIAL')
    AND (
        (p_partner_type = 'customer' AND customer_b2c_id = p_partner_id)
        OR
        (p_partner_type = 'customer_b2b' AND customer_id = p_partner_id)
    );

    -- 2. TÍNH TỔNG ĐÃ THU (Qua phiếu thu)
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid_via_finance
    FROM public.finance_transactions
    WHERE flow = 'in' AND status = 'completed'
    AND partner_id = p_partner_id::text
    AND partner_type = p_partner_type;

    -- 3. KẾT QUẢ: (Tổng phải thu - Tổng đã thu)
    RETURN v_total_sales - v_total_paid_via_finance;
END;
$function$
