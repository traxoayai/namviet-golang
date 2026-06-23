CREATE OR REPLACE FUNCTION public.get_applicable_vouchers(p_customer_id bigint, p_order_total numeric)
 RETURNS TABLE(id uuid, code text, description text, discount_value numeric, discount_type text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id, p.code, p.name as description, p.discount_value, p.discount_type
    FROM public.promotions p
    WHERE 
        p.status = 'active'
        AND now() BETWEEN p.valid_from AND p.valid_to
        AND p.min_order_value <= p_order_total
        AND (
            p.apply_to_scope = 'all' 
            OR (p.apply_to_scope = 'personal' AND p.customer_id = p_customer_id)
        )
    ORDER BY p.discount_value DESC;
END;
$function$
