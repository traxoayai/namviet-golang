CREATE OR REPLACE FUNCTION public.get_product_cardex(p_product_id bigint, p_warehouse_id bigint, p_from_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_to_date timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(transaction_date timestamp with time zone, type text, business_type text, quantity numeric, unit_price numeric, ref_code text, partner_name text, description text, created_by_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        it.created_at,
        CASE WHEN it.quantity > 0 THEN 'in' ELSE 'out' END as type,
        it.type as business_type,
        
        -- [FIX SENKO] Ép kiểu tường minh sang NUMERIC để khớp với khai báo
        ABS(it.quantity)::NUMERIC as quantity, 
        COALESCE(it.unit_price, 0)::NUMERIC as unit_price,
        
        it.ref_id as ref_code, 
        
        -- Logic lấy tên đối tác (Giữ nguyên từ V41 vì nó cover cả B2B)
        COALESCE(
            s.name,           -- Nhà cung cấp
            cb.name,          -- Khách B2B
            c.name,           -- Khách Lẻ
            'N/A'
        ) as partner_name, 
        
        it.description,
        u.full_name as created_by_name
    FROM public.inventory_transactions it
    LEFT JOIN public.users u ON it.created_by = u.id
    -- Join các bảng đối tác (Lưu ý: Nếu ID trùng nhau giữa các bảng thì có thể sai lệch nếu không có partner_type, 
    -- nhưng hiện tại schema chưa có partner_type nên ta chấp nhận rủi ro thấp này)
    LEFT JOIN public.suppliers s ON it.partner_id = s.id 
    LEFT JOIN public.customers_b2b cb ON it.partner_id = cb.id 
    LEFT JOIN public.customers c ON it.partner_id = c.id
    
    WHERE it.product_id = p_product_id
      AND it.warehouse_id = p_warehouse_id
      AND (p_from_date IS NULL OR it.created_at >= p_from_date)
      AND (p_to_date IS NULL OR it.created_at <= p_to_date)
    ORDER BY it.created_at DESC;
END;
$function$
