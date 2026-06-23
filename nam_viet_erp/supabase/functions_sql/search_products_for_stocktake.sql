CREATE OR REPLACE FUNCTION public.search_products_for_stocktake(p_keyword text, p_warehouse_id bigint)
 RETURNS TABLE(id bigint, sku text, name text, image_url text, unit text, wholesale_unit text, retail_unit text, items_per_carton integer, system_stock numeric, location text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_clean_keyword text;
    v_search_pattern text;
BEGIN
    -- 1. Làm sạch từ khóa (xóa khoảng trắng thừa)
    v_clean_keyword := trim(regexp_replace(p_keyword, '\s+', ' ', 'g'));
    
    -- 2. Tạo Pattern tìm kiếm thông minh
    -- Biến "pana ex" thành "%pana%ex%" để tìm các từ phân tán
    v_search_pattern := '%' || replace(unaccent(v_clean_keyword), ' ', '%') || '%';
    
    RETURN QUERY
    SELECT 
        p.id::bigint,
        p.sku::text,
        p.name::text,
        p.image_url::text,
        COALESCE(u_base.unit_name, 'Đv')::text,
        p.wholesale_unit::text,
        p.retail_unit::text,
        COALESCE(p.items_per_carton, 1)::int,
        COALESCE(inv.stock_quantity, 0)::numeric as system_stock,
        (COALESCE(NULLIF(inv.location_cabinet, '') || '-', '') || 
         COALESCE(NULLIF(inv.location_row, '') || '-', '') || 
         COALESCE(inv.location_slot, ''))::text as location
    FROM public.products p
    LEFT JOIN public.product_inventory inv 
        ON p.id = inv.product_id AND inv.warehouse_id = p_warehouse_id
    LEFT JOIN public.product_units u_base 
        ON p.id = u_base.product_id AND u_base.is_base = true
    WHERE 
        p.status = 'active'
        AND (
            -- Ưu tiên 1: Tìm chính xác SKU/Barcode (Không cần unaccent)
            p.barcode ILIKE v_clean_keyword
            OR p.sku ILIKE v_clean_keyword || '%'
            -- Ưu tiên 2: Tìm tên theo Pattern thông minh (Có unaccent)
            -- Logic: unaccent("Panadol Extra") LIKE "%pana%ex%" -> MATCH!
            OR unaccent(p.name) ILIKE v_search_pattern
        )
    ORDER BY 
        -- Sắp xếp: Khớp SKU lên đầu, sau đó đến khớp tên
        CASE WHEN p.sku ILIKE v_clean_keyword || '%' THEN 1 ELSE 2 END,
        p.name ASC
    LIMIT 20;
END;
$function$
