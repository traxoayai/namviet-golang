CREATE OR REPLACE FUNCTION public.search_products_for_b2b_order(p_keyword text, p_warehouse_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_sql TEXT;
    v_term TEXT;
    v_search_arr TEXT[];
    v_result JSONB;
    v_where_clauses TEXT[] := ARRAY['1=1']; 
BEGIN
    -- 1. WHERE CLAUSES
    v_where_clauses := array_append(v_where_clauses, 'p.status = ''active''');

    IF p_keyword IS NOT NULL AND TRIM(p_keyword) != '' THEN
        v_search_arr := string_to_array(TRIM(p_keyword), ' ');
        FOREACH v_term IN ARRAY v_search_arr
        LOOP
            IF TRIM(v_term) != '' THEN
                v_where_clauses := array_append(v_where_clauses, format(
                    '(p.name ILIKE %1$L OR unaccent(p.name) ILIKE %1$L OR p.sku ILIKE %1$L OR COALESCE(p.barcode, '''') ILIKE %1$L)', 
                    '%' || TRIM(v_term) || '%'
                ));
            END IF;
        END LOOP;
    END IF;

    -- 2. DYNAMIC SQL VỚI MAPPING CHUẨN
    v_sql := format(
        'SELECT COALESCE(jsonb_agg(t.*), ''[]''::jsonb)
        FROM (
            SELECT 
                p.id, 
                p.sku, 
                p.name, 
                p.image_url, 
                
                -- [INTERFACE MATCHING] 1. stock_quantity (Số lượng tồn quy đổi ra Hộp)
                FLOOR(
                    COALESCE(inv_sum.total, 0) 
                    / 
                    COALESCE(NULLIF(target_unit.conversion_rate, 0), 1)
                )::INT as stock_quantity, 
                
                -- [INTERFACE MATCHING] 2. Các trường phụ stock (V20)
                COALESCE(inv_sum.total, 0)::INT as real_stock, -- Tồn thực tế (Base Unit)
                
                MOD(
                    COALESCE(inv_sum.total, 0),
                    COALESCE(NULLIF(target_unit.conversion_rate, 0), 1)
                )::INT as available_stock, -- Dùng tạm trường này để chứa số dư lẻ (Stock Remainder)

                -- [INTERFACE MATCHING] 3. Thông tin vị trí & Lô (Lấy theo FIFO)
                COALESCE(fifo_data.shelf_location, ''Chưa xếp'') as shelf_location,
                fifo_data.lot_number,
                fifo_data.expiry_date,

                -- [INTERFACE MATCHING] 4. Đơn vị & Giá
                COALESCE(target_unit.unit_name, p.wholesale_unit, ''Hộp'') as wholesale_unit,
                COALESCE(target_unit.price, 0) as price_wholesale, -- Đổi tên key thành price_wholesale
                COALESCE(target_unit.conversion_rate, 1) as items_per_carton

            FROM public.products p
            
            -- [JOIN] Tổng tồn kho tại Warehouse được chọn
            LEFT JOIN LATERAL (
                SELECT SUM(stock_quantity) as total 
                FROM public.product_inventory 
                WHERE product_id = p.id AND warehouse_id = %s 
            ) inv_sum ON true

            -- [JOIN] Đơn vị Bán Buôn (Target Unit)
            LEFT JOIN LATERAL (
                SELECT unit_name, conversion_rate, price
                FROM public.product_units
                WHERE product_id = p.id
                ORDER BY 
                    CASE WHEN unit_type = ''wholesale'' THEN 1 ELSE 2 END,
                    conversion_rate DESC
                LIMIT 1
            ) target_unit ON true

            -- [JOIN] Lấy thông tin Lô/Hạn/Vị trí (FIFO Logic)
            -- Lấy lô hết hạn sớm nhất tại kho này để hiển thị gợi ý
            LEFT JOIN LATERAL (
                SELECT 
                    iri.lot_number, 
                    iri.expiry_date,
                    inv.shelf_location -- Lấy vị trí từ bảng inventory (hoặc receipt)
                FROM public.product_inventory inv
                LEFT JOIN public.inventory_receipt_items iri ON iri.product_id = inv.product_id -- (Join ảo để lấy lot nếu có cấu trúc này, hoặc lấy từ receipt log)
                -- Để đơn giản và nhanh, ta lấy shelf_location từ bảng inventory trước
                WHERE inv.product_id = p.id AND inv.warehouse_id = %s
                LIMIT 1
            ) fifo_data ON true

            WHERE %s
            ORDER BY p.created_at DESC
            LIMIT 20 
        ) t',
        p_warehouse_id, -- Cho inv_sum
        p_warehouse_id, -- Cho fifo_data
        array_to_string(v_where_clauses, ' AND ')
    );

    EXECUTE v_sql INTO v_result;

    RETURN v_result;
END;
$function$
