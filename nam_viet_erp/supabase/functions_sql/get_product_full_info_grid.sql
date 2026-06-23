CREATE OR REPLACE FUNCTION public.get_product_full_info_grid(p_search text DEFAULT ''::text, p_category text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS TABLE(product_id bigint, sku text, name text, status text, image_url text, barcode text, manufacturer_name text, category_name text, active_ingredient text, actual_cost numeric, base_unit_name text, retail_unit_name text, retail_conversion_rate integer, retail_price numeric, wholesale_unit_name text, wholesale_conversion_rate integer, logistic_unit_name text, logistic_conversion_rate integer, retail_margin_value numeric, retail_margin_type text, wholesale_margin_value numeric, wholesale_margin_type text, total_system_stock bigint, created_at timestamp with time zone, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id as product_id,
        p.sku,
        p.name,
        p.status,
        p.image_url,
        p.barcode,
        p.manufacturer_name,
        p.category_name,
        p.active_ingredient,
        
        COALESCE(p.actual_cost, 0) as actual_cost,
        
        -- Base Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.is_base = true LIMIT 1) as base_unit_name,
        
        -- Retail Unit & Price
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'retail' LIMIT 1) as retail_unit_name,
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'retail' LIMIT 1) as retail_conversion_rate,
        (SELECT price FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'retail' LIMIT 1) as retail_price,
        
        -- Wholesale Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'wholesale' LIMIT 1) as wholesale_unit_name,
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'wholesale' LIMIT 1) as wholesale_conversion_rate,
        
        -- Logistic Unit
        (SELECT unit_name FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'logistic' LIMIT 1) as logistic_unit_name,
        (SELECT conversion_rate::integer FROM public.product_units u WHERE u.product_id = p.id AND u.unit_type = 'logistic' LIMIT 1) as logistic_conversion_rate,
        
        -- Margins
        p.retail_margin_value,
        p.retail_margin_type,
        p.wholesale_margin_value,
        p.wholesale_margin_type,
        
        -- Tổng tồn kho (Sum từ bảng inventory)
        COALESCE((SELECT SUM(stock_quantity) FROM public.product_inventory WHERE product_id = p.id), 0)::bigint as total_system_stock,
        
        p.created_at,
        (COUNT(*) OVER()) as total_count
        
    FROM public.products p
    WHERE 
        (p_search IS NULL OR p_search = '' OR 
         p.name ILIKE '%' || p_search || '%' OR 
         p.sku ILIKE '%' || p_search || '%' OR 
         COALESCE(p.barcode, '') ILIKE '%' || p_search || '%')
        AND (p_category IS NULL OR p_category = '' OR p.category_name = p_category)
        AND (p_status IS NULL OR p.status = p_status)
        AND p.status != 'deleted' -- Mặc định không lấy hàng đã xóa
        
    ORDER BY p.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;
$function$
