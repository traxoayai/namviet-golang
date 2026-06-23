CREATE OR REPLACE FUNCTION public.get_pending_reconciliation_orders()
 RETURNS TABLE(order_id uuid, order_code text, created_at timestamp with time zone, customer_code text, customer_name text, final_amount numeric, paid_amount numeric, remaining_amount numeric, payment_method text, source text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        o.id as order_id,
        o.code as order_code,
        o.created_at,
        
        -- Lấy mã khách hàng (Ưu tiên B2B -> B2C -> N/A)
        COALESCE(cb.customer_code, cc.customer_code, 'N/A') as customer_code,
        
        -- Lấy tên khách (Ưu tiên B2B -> B2C -> Khách lẻ)
        COALESCE(cb.name, cc.name, 'Khách lẻ') as customer_name,
        
        o.final_amount,
        COALESCE(o.paid_amount, 0) as paid_amount,
        (o.final_amount - COALESCE(o.paid_amount, 0)) as remaining_amount,
        
        COALESCE(o.payment_method, 'unknown') as payment_method,
        o.order_type as source
    FROM public.orders o
    LEFT JOIN public.customers_b2b cb ON o.customer_id = cb.id
    LEFT JOIN public.customers cc ON o.customer_b2c_id = cc.id
    WHERE 
        o.status NOT IN ('DRAFT', 'CANCELLED', 'QUOTE', 'QUOTE_EXPIRED') -- Loại bỏ các trạng thái rác
        AND o.payment_status != 'paid' -- Chỉ lấy đơn chưa trả hết
        -- Chỉ lấy các phương thức cần đối soát qua ngân hàng
        -- (Loại bỏ 'cash' hoặc các phương thức trả ngay tại quầy nếu có)
        AND (o.payment_method IN ('bank_transfer', 'debt', 'transfer') OR o.payment_method IS NULL)
    ORDER BY o.created_at DESC;
END;
$function$
