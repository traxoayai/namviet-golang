CREATE OR REPLACE FUNCTION public.get_available_vouchers(p_customer_id bigint, p_order_total numeric)
 RETURNS TABLE(id uuid, code text, name text, description text, discount_type text, discount_value numeric, max_discount_value numeric, min_order_value numeric, valid_to timestamp with time zone)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id, p.code, p.name, p.description, 
        p.discount_type, p.discount_value, p.max_discount_value, 
        p.min_order_value, p.valid_to
    FROM public.promotions p
    WHERE 
        p.status = 'active'
        AND now() BETWEEN p.valid_from AND p.valid_to
        AND p_order_total >= p.min_order_value
        -- Kiểm tra giới hạn tổng
        AND (p.total_usage_limit IS NULL OR p.usage_count < p.total_usage_limit)
        -- Kiểm tra phạm vi áp dụng (Scope)
        AND (
            p.apply_to_scope = 'all' 
            OR (p.apply_to_scope = 'personal' AND p.customer_id = p_customer_id)
        )
        -- Kiểm tra giới hạn từng người (Subquery)
        AND (
            p.usage_limit_per_user IS NULL 
            OR (
                SELECT COUNT(*) 
                FROM public.promotion_usages pu 
                WHERE pu.promotion_id = p.id AND pu.customer_id = p_customer_id
            ) < p.usage_limit_per_user
        )
    ORDER BY p.discount_value DESC; -- Ưu tiên giảm giá cao nhất
END;
$function$
