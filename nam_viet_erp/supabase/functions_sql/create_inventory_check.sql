CREATE OR REPLACE FUNCTION public.create_inventory_check(p_warehouse_id bigint, p_user_id uuid, p_note text DEFAULT NULL::text, p_scope text DEFAULT 'ALL'::text, p_text_val text DEFAULT NULL::text, p_int_val bigint DEFAULT NULL::bigint)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_check_id BIGINT;
        v_code TEXT;
    BEGIN
        -- A. Tạo mã phiếu KK-YYMMDD-HHMMSS
        v_code := 'KK-' || TO_CHAR(NOW(), 'YYYYMMDD-HH24MISS');

        -- B. Insert Header
        INSERT INTO public.inventory_checks (
            code, warehouse_id, status, note, created_by, total_system_value
        )
        VALUES (
            v_code, p_warehouse_id, 'DRAFT', p_note, p_user_id, 0
        )
        RETURNING id INTO v_check_id;

        -- C. Insert Items (SNAPSHOT)
        INSERT INTO public.inventory_check_items (
            check_id, product_id, batch_code, expiry_date, 
            system_quantity, actual_quantity, cost_price, location_snapshot
        )
        SELECT 
            v_check_id,
            ib.product_id,
            b.batch_code,
            b.expiry_date,
            ib.quantity, -- System Quantity
            ib.quantity, -- Actual Default = System
            p.actual_cost,
            inv.shelf_location
        FROM public.inventory_batches ib
        JOIN public.batches b ON ib.batch_id = b.id
        JOIN public.products p ON ib.product_id = p.id
        LEFT JOIN public.product_inventory inv ON ib.product_id = inv.product_id AND ib.warehouse_id = inv.warehouse_id
        
        WHERE ib.warehouse_id = p_warehouse_id 
          AND ib.quantity > 0
          
          -- [LOGIC LỌC MỚI THEO YÊU CẦU]
          AND (
              (p_scope = 'ALL') 
              OR
              (p_scope = 'CATEGORY' AND p.category_name = p_text_val) 
              OR
              -- Thay đổi từ Supplier ID sang Manufacturer Name
              (p_scope = 'MANUFACTURER' AND p.manufacturer_name = p_text_val) 
              OR
              (p_scope = 'CABINET' AND inv.location_cabinet = p_text_val)
          );

        -- D. Cập nhật tổng tiền sổ sách
        UPDATE public.inventory_checks 
        SET total_system_value = (
            SELECT COALESCE(SUM(system_quantity * cost_price), 0) 
            FROM public.inventory_check_items WHERE check_id = v_check_id
        )
        WHERE id = v_check_id;

        RETURN v_check_id;
    END;
    $function$
