CREATE OR REPLACE FUNCTION public.search_products_for_transfer(p_warehouse_id bigint, p_keyword text DEFAULT ''::text, p_limit integer DEFAULT 20)
 RETURNS TABLE(id bigint, sku text, name text, image_url text, current_stock integer, shelf_location text, lot_number text, expiry_date date, unit text, conversion_factor integer, items_per_carton integer, stock_display text)
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
    v_clean_keyword text;
    v_search_query tsquery;
BEGIN
    -- Chuẩn hóa từ khóa
    v_clean_keyword := trim(regexp_replace(p_keyword, '\s+', ' ', 'g'));
    
    IF v_clean_keyword IS NOT NULL AND v_clean_keyword <> '' THEN
        BEGIN
            v_search_query := to_tsquery('simple', replace(v_clean_keyword, ' ', ':* & ') || ':*');
        EXCEPTION WHEN OTHERS THEN
            v_search_query := plainto_tsquery('simple', v_clean_keyword);
        END;
    END IF;

    RETURN QUERY
    SELECT 
        p.id,
        p.sku,
        p.name,
        p.image_url,
        
        -- Lấy tồn kho chính xác tại kho nguồn (Theo Base Unit)
        COALESCE(inv.stock_quantity, 0)::INTEGER as current_stock,
        COALESCE(inv.shelf_location, '') as shelf_location,
        
        -- Join đúng bảng batches để lấy batch_code
        (
            SELECT b.batch_code 
            FROM public.inventory_batches ib
            JOIN public.batches b ON ib.batch_id = b.id
            WHERE ib.product_id = p.id 
              AND ib.warehouse_id = p_warehouse_id 
              AND ib.quantity > 0 
              AND b.expiry_date >= CURRENT_DATE
            ORDER BY b.expiry_date ASC 
            LIMIT 1
        ) as lot_number,
        
        -- Lấy hạn sử dụng
        (
            SELECT b.expiry_date 
            FROM public.inventory_batches ib
            JOIN public.batches b ON ib.batch_id = b.id
            WHERE ib.product_id = p.id 
              AND ib.warehouse_id = p_warehouse_id 
              AND ib.quantity > 0 
              AND b.expiry_date >= CURRENT_DATE
            ORDER BY b.expiry_date ASC 
            LIMIT 1
        ) as expiry_date,
        
        -- Tìm đơn vị Wholesale tốt nhất
        COALESCE(u_b2b.unit_name, p.wholesale_unit, p.retail_unit, 'Hộp') as unit,
        COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1) as conversion_factor,
        COALESCE(p.items_per_carton, 1) as items_per_carton,

        -- Xây dựng chuỗi hiển thị tồn kho thông minh
        CASE 
            WHEN COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1) > 1 THEN 
                CASE 
                    WHEN COALESCE(inv.stock_quantity, 0) >= COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1) AND MOD(COALESCE(inv.stock_quantity, 0)::numeric, COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1)::numeric) > 0 THEN
                        FLOOR(COALESCE(inv.stock_quantity, 0) / COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1))::int::text || ' ' || COALESCE(u_b2b.unit_name, p.wholesale_unit, 'Hộp') || ' + ' || MOD(COALESCE(inv.stock_quantity, 0)::numeric, COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1)::numeric)::int::text || ' ' || COALESCE(u_base.unit_name, p.retail_unit, 'ĐV')
                    WHEN COALESCE(inv.stock_quantity, 0) >= COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1) THEN
                        FLOOR(COALESCE(inv.stock_quantity, 0) / COALESCE(u_b2b.conversion_rate, p.items_per_carton, 1))::int::text || ' ' || COALESCE(u_b2b.unit_name, p.wholesale_unit, 'Hộp')
                    ELSE
                        COALESCE(inv.stock_quantity, 0)::int::text || ' ' || COALESCE(u_base.unit_name, p.retail_unit, 'ĐV')
                END
            ELSE COALESCE(inv.stock_quantity, 0)::int::text || ' ' || COALESCE(u_base.unit_name, p.retail_unit, 'ĐV')
        END as stock_display

    FROM public.products p
    LEFT JOIN public.product_inventory inv 
        ON p.id = inv.product_id AND inv.warehouse_id = p_warehouse_id
    
    -- Subquery lấy đơn vị lớn
    LEFT JOIN LATERAL (
        SELECT unit_name, conversion_rate
        FROM public.product_units pu
        WHERE pu.product_id = p.id
        ORDER BY (pu.unit_type = 'wholesale') DESC, pu.conversion_rate DESC
        LIMIT 1
    ) u_b2b ON TRUE

    -- Subquery lấy đơn vị nhỏ (Base unit) để ghép chuỗi
    LEFT JOIN LATERAL (
        SELECT unit_name FROM public.product_units pu 
        WHERE pu.product_id = p.id AND pu.unit_type = 'base' LIMIT 1
    ) u_base ON TRUE
    
    WHERE 
        p.status = 'active'
        AND (
            v_clean_keyword IS NULL 
            OR v_clean_keyword = ''
            OR p.sku ILIKE v_clean_keyword || '%'
            OR p.barcode = v_clean_keyword
            OR p.fts @@ v_search_query
            OR p.name ILIKE '%' || v_clean_keyword || '%'
        )
    ORDER BY 
        (COALESCE(inv.stock_quantity, 0) > 0) DESC,
        p.created_at DESC
    LIMIT p_limit;
END;
$function$
