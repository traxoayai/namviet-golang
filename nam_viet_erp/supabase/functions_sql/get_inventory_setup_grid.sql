CREATE OR REPLACE FUNCTION public.get_inventory_setup_grid(p_warehouse_id bigint, p_search text DEFAULT ''::text, p_has_setup_only boolean DEFAULT false, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(product_id bigint, sku text, name text, image_url text, actual_cost numeric, unit_name text, conversion_rate integer, min_stock integer, max_stock integer, current_stock integer, distributor_id bigint, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$BEGIN
    RETURN QUERY
    WITH filtered_products AS (
        SELECT p.id, p.sku, p.name, p.image_url, p.actual_cost, p.distributor_id, p.created_at
        FROM public.products p
        WHERE p.status = 'active'
          AND (p_search IS NULL OR p_search = '' OR p.name ILIKE '%' || p_search || '%' OR p.sku ILIKE '%' || p_search || '%')
    )
    SELECT 
        fp.id as product_id,
        fp.sku,
        fp.name,
        fp.image_url,
        COALESCE(fp.actual_cost, 0) as actual_cost,
        
        COALESCE(u_wholesale.unit_name, u_base.unit_name, 'Cái') as unit_name,
        COALESCE(u_wholesale.conversion_rate::integer, 1) as conversion_rate,
        
        COALESCE(inv.min_stock, 0) as min_stock,
        COALESCE(inv.max_stock, 0) as max_stock,
        COALESCE(inv.stock_quantity, 0)::integer as current_stock,
        
        fp.distributor_id, 
        
        (COUNT(*) OVER()) as total_count
        
    FROM filtered_products fp
    LEFT JOIN public.product_units u_base ON fp.id = u_base.product_id AND u_base.is_base = true
    LEFT JOIN public.product_units u_wholesale ON fp.id = u_wholesale.product_id AND u_wholesale.unit_type = 'wholesale'
    LEFT JOIN public.product_inventory inv ON fp.id = inv.product_id AND inv.warehouse_id = p_warehouse_id
    
    WHERE 
        (p_has_setup_only = false OR (inv.min_stock > 0 OR inv.max_stock > 0))
        
    ORDER BY fp.created_at DESC
    LIMIT p_limit
    OFFSET p_offset;
END;$function$
