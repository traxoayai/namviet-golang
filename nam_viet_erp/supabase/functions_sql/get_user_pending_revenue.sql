CREATE OR REPLACE FUNCTION public.get_user_pending_revenue(p_user_id uuid)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_total numeric;
    BEGIN
        SELECT COALESCE(SUM(final_amount), 0)
        INTO v_total
        FROM public.orders
        WHERE creator_id = p_user_id -- [CORE FIX]: Dùng đúng cột creator_id
          AND payment_method = 'cash' 
          AND remittance_status = 'pending' 
          AND status IN ('COMPLETED', 'DELIVERED', 'SHIPPING', 'PACKED', 'CONFIRMED');
          
        RETURN v_total;
    END;
    $function$
