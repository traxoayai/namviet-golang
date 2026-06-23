CREATE OR REPLACE FUNCTION public.update_product_location(p_warehouse_id bigint, p_product_id bigint, p_cabinet text, p_row text, p_slot text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_full_location TEXT;
    BEGIN
        -- 1. Tạo chuỗi hiển thị (Legacy support)
        -- Dùng NULLIF để biến chuỗi rỗng '' thành NULL, tránh lỗi format '--'
        v_full_location := CONCAT_WS('-', NULLIF(p_cabinet, ''), NULLIF(p_row, ''), NULLIF(p_slot, ''));
        
        IF v_full_location = '' THEN v_full_location := NULL; END IF;

        -- 2. UPSERT (Quan trọng)
        -- Logic: Thử Insert với tồn kho = 0. Nếu đã có thì chỉ Update vị trí.
        INSERT INTO public.product_inventory (
            warehouse_id, 
            product_id, 
            stock_quantity, -- Mặc định 0 nếu là record mới
            location_cabinet, 
            location_row, 
            location_slot, 
            shelf_location,
            updated_at,
            min_stock,
            max_stock
        )
        VALUES (
            p_warehouse_id,
            p_product_id,
            0, -- Stock quantity default
            p_cabinet,
            p_row,
            p_slot,
            v_full_location,
            NOW(),
            0, -- Default min
            0  -- Default max
        )
        ON CONFLICT (product_id, warehouse_id) 
        DO UPDATE SET 
            location_cabinet = EXCLUDED.location_cabinet,
            location_row = EXCLUDED.location_row,
            location_slot = EXCLUDED.location_slot,
            shelf_location = EXCLUDED.shelf_location,
            updated_at = NOW();
    END;
    $function$
