CREATE OR REPLACE FUNCTION public.search_products_pos(p_keyword text, p_warehouse_id bigint, p_limit integer DEFAULT 20)
 RETURNS TABLE(id bigint, name text, sku text, barcode text, retail_price numeric, image_url text, unit text, stock_quantity integer, location_cabinet text, location_row text, location_slot text, usage_instructions jsonb, status text, similarity_score real)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_clean_keyword text;
    v_search_pattern text;
    v_warehouse_type text;
BEGIN
    SELECT w.type INTO v_warehouse_type FROM public.warehouses w WHERE w.id = p_warehouse_id;
    IF v_warehouse_type = 'wholesale' THEN RETURN; END IF;

    v_clean_keyword := TRIM(p_keyword);
    IF v_clean_keyword IS NULL OR v_clean_keyword = '' THEN RETURN; END IF;
    v_search_pattern := '%' || REPLACE(v_clean_keyword, ' ', '%') || '%';

    RETURN QUERY
    SELECT 
        p.id, p.name, p.sku, p.barcode,
        COALESCE(u_retail.price_sell, 0), 
        p.image_url,
        COALESCE(u_retail.unit_name, u_base.unit_name, 'N/A'),
        
        -- [CORE FIX]: Chia tồn kho Base cho tỷ lệ quy đổi để ra số lượng hiển thị (VD: 180 viên / 12 = 15 vỉ)
        FLOOR(COALESCE(inv.stock_quantity, 0)::NUMERIC / GREATEST(COALESCE(u_retail.conversion_rate, 1), 1))::INTEGER,
        
        inv.location_cabinet, inv.location_row, inv.location_slot, p.usage_instructions, p.status,
        CASE 
            WHEN p.barcode = v_clean_keyword THEN 1.0::REAL
            ELSE GREATEST(similarity(p.name, v_clean_keyword), 0.5)::REAL
        END AS score
    FROM public.products p
    LEFT JOIN public.product_units u_retail ON p.id = u_retail.product_id AND u_retail.unit_type = 'retail'
    LEFT JOIN public.product_units u_base ON p.id = u_base.product_id AND u_base.is_base = true
    LEFT JOIN public.product_inventory inv ON p.id = inv.product_id AND inv.warehouse_id = p_warehouse_id
    WHERE p.status = 'active' 
      AND (p.barcode = v_clean_keyword OR p.sku ILIKE v_clean_keyword || '%' OR p.name ILIKE v_search_pattern)
    ORDER BY score DESC, inv.stock_quantity DESC NULLS LAST
    LIMIT p_limit;
END;
$function$
