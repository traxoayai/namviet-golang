CREATE OR REPLACE FUNCTION public.search_products_v2(p_keyword text DEFAULT ''::text, p_status text DEFAULT ''::text, p_category text DEFAULT ''::text, p_manufacturer text DEFAULT ''::text, p_warehouse_id integer DEFAULT NULL::integer, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_sql TEXT;
    v_term TEXT;
    v_search_arr TEXT[];
    v_result JSONB;
    v_where_clauses TEXT[] := ARRAY['1=1']; 
    v_stock_cond TEXT := ''; 
BEGIN
    IF p_status IS NOT NULL AND p_status != '' THEN
        v_where_clauses := array_append(v_where_clauses, format('p.status = %L', p_status));
    ELSE
        v_where_clauses := array_append(v_where_clauses, 'p.status = ''active''');
    END IF;

    IF p_manufacturer IS NOT NULL AND p_manufacturer != '' THEN
        v_where_clauses := array_append(v_where_clauses, format('p.manufacturer_name = %L', p_manufacturer));
    END IF;

    IF p_category IS NOT NULL AND p_category != '' THEN
        v_where_clauses := array_append(v_where_clauses, format('p.category_name = %L', p_category));
    END IF;

    IF p_keyword IS NOT NULL AND TRIM(p_keyword) != '' THEN
        v_search_arr := string_to_array(TRIM(p_keyword), ' ');
        FOREACH v_term IN ARRAY v_search_arr
        LOOP
            IF TRIM(v_term) != '' THEN
                v_where_clauses := array_append(v_where_clauses, format(
                    '(p.name ILIKE %1$L OR p.sku ILIKE %1$L OR COALESCE(p.barcode, '''') ILIKE %1$L OR COALESCE(p.active_ingredient, '''') ILIKE %1$L)', 
                    '%' || TRIM(v_term) || '%'
                ));
            END IF;
        END LOOP;
    END IF;

    IF p_warehouse_id IS NOT NULL THEN
        v_stock_cond := format('AND warehouse_id = %s', p_warehouse_id);
    END IF;

    v_sql := format($q$
        SELECT jsonb_build_object(
            'data', COALESCE(jsonb_agg(t.*), '[]'::jsonb),
            'total_count', COALESCE(MAX(t.full_count), 0)
        )
        FROM (
            SELECT 
                p.id, p.name, p.sku, p.barcode, p.image_url, p.status, 
                p.manufacturer_name AS manufacturer, p.category_name AS category, p.active_ingredient,
                COALESCE(p.actual_cost, 0) AS actual_cost,
                
                -- 1. Lấy Base Unit
                COALESCE((SELECT unit_name FROM public.product_units WHERE product_id = p.id AND (unit_type = 'base' OR is_base = true) LIMIT 1), 'Viên') as base_unit,
                
                -- 2. Lấy Retail Unit + Rate + Price
                COALESCE((SELECT unit_name FROM public.product_units WHERE product_id = p.id AND unit_type = 'retail' LIMIT 1), 'Vỉ') as retail_unit,
                COALESCE((SELECT conversion_rate FROM public.product_units WHERE product_id = p.id AND unit_type = 'retail' LIMIT 1), 1) as retail_conversion_rate,
                COALESCE((SELECT price_sell FROM public.product_units WHERE product_id = p.id AND unit_type = 'retail' LIMIT 1), 0) as retail_price,
                
                -- 3. Lấy Wholesale Unit + Rate + Price
                COALESCE((SELECT unit_name FROM public.product_units WHERE product_id = p.id AND unit_type = 'wholesale' LIMIT 1), 'Hộp') as wholesale_unit,
                COALESCE((SELECT conversion_rate FROM public.product_units WHERE product_id = p.id AND unit_type = 'wholesale' LIMIT 1), p.items_per_carton, 1) as wholesale_conversion_rate,
                p.items_per_carton, -- Vẫn giữ lại để tương thích ngược

                %1$s::int as warehouse_id,

                COALESCE((
                    SELECT jsonb_object_agg(
                        COALESCE(w.name, 'Kho ' || stock_data.warehouse_id),
                        CASE 
                            WHEN max_u.rate > 1 THEN 
                                CASE 
                                    WHEN stock_data.total_qty >= max_u.rate AND MOD(stock_data.total_qty::numeric, max_u.rate::numeric) > 0 THEN
                                        FLOOR(stock_data.total_qty / max_u.rate)::int::text || ' ' || max_u.name || ' + ' || MOD(stock_data.total_qty::numeric, max_u.rate::numeric)::int::text || ' ' || COALESCE(base_u.name, 'ĐV')
                                    WHEN stock_data.total_qty >= max_u.rate THEN
                                        FLOOR(stock_data.total_qty / max_u.rate)::int::text || ' ' || max_u.name
                                    ELSE
                                        stock_data.total_qty::int::text || ' ' || COALESCE(base_u.name, 'ĐV')
                                END
                            ELSE stock_data.total_qty::int::text || ' ' || COALESCE(base_u.name, 'ĐV')
                        END
                    )
                    FROM (
                        SELECT warehouse_id, SUM(stock_quantity) as total_qty
                        FROM public.product_inventory
                        WHERE product_id = p.id
                        GROUP BY warehouse_id
                        HAVING SUM(stock_quantity) > 0
                    ) stock_data
                    LEFT JOIN public.warehouses w ON w.id = stock_data.warehouse_id
                    LEFT JOIN LATERAL (
                        SELECT unit_name as name FROM public.product_units pu WHERE pu.product_id = p.id AND pu.unit_type = 'base' LIMIT 1
                    ) base_u ON true
                    LEFT JOIN LATERAL (
                        SELECT unit_name as name, conversion_rate as rate FROM public.product_units pu WHERE pu.product_id = p.id AND pu.conversion_rate > 1 ORDER BY pu.conversion_rate DESC LIMIT 1
                    ) max_u ON true
                ), '{}'::jsonb) AS warehouse_stocks,

                COALESCE((
                    SELECT SUM(stock_quantity) FROM public.product_inventory WHERE product_id = p.id %2$s
                ), 0)::INT as total_stock,

                COUNT(*) OVER() as full_count

            FROM public.products p
            WHERE %3$s
            ORDER BY p.created_at DESC
            LIMIT %4$s OFFSET %5$s
        ) t
    $q$,
    COALESCE(p_warehouse_id::text, 'NULL'),     
    v_stock_cond,                               
    array_to_string(v_where_clauses, ' AND '),  
    p_limit,                                    
    p_offset                                    
    );

    EXECUTE v_sql INTO v_result;
    RETURN COALESCE(v_result, '{"data": [], "total_count": 0}'::jsonb);
END;
$function$
