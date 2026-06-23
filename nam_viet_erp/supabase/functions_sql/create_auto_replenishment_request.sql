CREATE OR REPLACE FUNCTION public.create_auto_replenishment_request(p_dest_warehouse_id bigint, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_source_warehouse_id BIGINT;
        v_transfer_id BIGINT;
        v_item_count INTEGER := 0;
        v_code TEXT;
        v_final_note TEXT;
    BEGIN
        -- 1. Xác định kho nguồn
        SELECT id INTO v_source_warehouse_id 
        FROM public.warehouses 
        WHERE key = 'b2b' OR type = 'central' 
        LIMIT 1;

        IF v_source_warehouse_id IS NULL THEN
            RAISE EXCEPTION 'Không tìm thấy Kho Tổng (Source Warehouse).';
        END IF;

        IF v_source_warehouse_id = p_dest_warehouse_id THEN
            RAISE EXCEPTION 'Kho nguồn và kho đích trùng nhau.';
        END IF;

        -- 2. Tạo Mã phiếu tạm
        v_code := public._gen_finance_tx_code('TRF');

        -- 3. [CRITICAL LOGIC CHANGE]
        CREATE TEMP TABLE temp_replenish_items AS
        SELECT 
            pi.product_id,
            
            -- Ưu tiên theo thứ tự: Wholesale Unit -> Largest Unit -> Base Unit -> N/A
            COALESCE(target_unit.unit_name, largest_unit.unit_name, base_unit.unit_name, 'N/A') AS unit,
            
            COALESCE(target_unit.conversion_rate, largest_unit.conversion_rate, 1) AS conversion_factor,
            
            -- Công thức: (Max - Current) / Conversion_Factor_Of_Wholesale
            FLOOR(
                (pi.max_stock - pi.stock_quantity)::NUMERIC / 
                COALESCE(NULLIF(target_unit.conversion_rate, 0), NULLIF(largest_unit.conversion_rate, 0), 1)
            ) AS qty_needed
            
        FROM public.product_inventory pi
        JOIN public.products p ON pi.product_id = p.id
        
        -- A. Tìm Đơn vị Bán buôn (Ưu tiên số 1)
        LEFT JOIN LATERAL (
            SELECT unit_name, conversion_rate
            FROM public.product_units pu
            WHERE pu.product_id = pi.product_id
            AND pu.unit_type = 'wholesale' -- [KEY CHANGE] Chỉ tìm loại Wholesale
            LIMIT 1
        ) target_unit ON TRUE
        
        -- B. Tìm Đơn vị Lớn nhất (Dự phòng nếu chưa cấu hình Wholesale)
        LEFT JOIN LATERAL (
            SELECT unit_name, conversion_rate
            FROM public.product_units pu
            WHERE pu.product_id = pi.product_id
            ORDER BY pu.conversion_rate DESC
            LIMIT 1
        ) largest_unit ON TRUE

        -- C. Tìm Đơn vị Cơ sở (Dự phòng cuối cùng)
        LEFT JOIN LATERAL (
            SELECT unit_name
            FROM public.product_units pu_base
            WHERE pu_base.product_id = pi.product_id 
            AND pu_base.unit_type = 'base'
            LIMIT 1
        ) base_unit ON TRUE
        
        WHERE pi.warehouse_id = p_dest_warehouse_id
          AND pi.max_stock > 0
          AND p.status = 'active';

        -- Lọc bỏ dòng qty <= 0
        DELETE FROM temp_replenish_items WHERE qty_needed <= 0;

        GET DIAGNOSTICS v_item_count = ROW_COUNT;

        -- Thoát nếu không có item
        IF v_item_count = 0 THEN
            DROP TABLE temp_replenish_items;
            RETURN jsonb_build_object('success', false, 'message', 'Kho đã đủ hàng (theo đơn vị bán buôn), không cần bù.');
        END IF;

        -- 4. Xử lý Ghi chú
        v_final_note := 'Yêu cầu bù kho (Ưu tiên đơn vị Bán buôn)';
        IF p_note IS NOT NULL AND TRIM(p_note) <> '' THEN
            v_final_note := v_final_note || '. ' || p_note;
        END IF;

        -- 5. Tạo Header
        INSERT INTO public.inventory_transfers (
            code, source_warehouse_id, dest_warehouse_id, status, created_by, note, is_urgent
        ) VALUES (
            v_code, v_source_warehouse_id, p_dest_warehouse_id, 'pending', auth.uid(), v_final_note, false
        ) RETURNING id INTO v_transfer_id;

        -- 6. Insert Items
        INSERT INTO public.inventory_transfer_items (
            transfer_id, product_id, unit, conversion_factor, qty_requested, qty_approved
        )
        SELECT v_transfer_id, product_id, unit, conversion_factor, qty_needed, qty_needed
        FROM temp_replenish_items;

        DROP TABLE temp_replenish_items;

        RETURN jsonb_build_object(
            'success', true, 
            'transfer_id', v_transfer_id, 
            'item_count', v_item_count, 
            'message', 'Đã tạo phiếu yêu cầu (Tính theo đơn vị Wholesale).'
        );
    END;
    $function$
