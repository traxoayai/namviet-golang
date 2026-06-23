CREATE OR REPLACE FUNCTION public.create_check_session(p_warehouse_id bigint, p_note text, p_scope text, p_text_val text DEFAULT NULL::text, p_int_val bigint DEFAULT NULL::bigint, p_user_id uuid DEFAULT auth.uid())
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
    v_code := 'KK-' || TO_CHAR(NOW(), 'YYMMDD-HH24MISS');

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
        ib.quantity, -- Actual Default = System (Ban đầu coi như khớp)
        p.actual_cost,
        
        -- [CORE OPTIMIZATION] Snapshot vị trí đầy đủ
        -- Nếu có cả Tủ và Kệ -> "Tủ A - Kệ 01"
        -- Nếu chỉ có Tủ -> "Tủ A"
        -- Nếu rỗng -> NULL
        TRIM(BOTH ' - ' FROM COALESCE(inv.location_cabinet, '') || CASE WHEN inv.shelf_location IS NOT NULL AND inv.shelf_location <> '' THEN ' - ' || inv.shelf_location ELSE '' END)
    FROM public.inventory_batches ib
    JOIN public.batches b ON ib.batch_id = b.id
    JOIN public.products p ON ib.product_id = p.id
    LEFT JOIN public.product_inventory inv ON ib.product_id = inv.product_id AND ib.warehouse_id = inv.warehouse_id
    
    WHERE ib.warehouse_id = p_warehouse_id 
      AND ib.quantity > 0 -- Chỉ kiểm những lô còn hàng
      
      -- [LOGIC LỌC ĐA NĂNG]
      AND (
          (p_scope = 'ALL') 
          OR
          (p_scope = 'CATEGORY' AND p.category_name = p_text_val) 
          OR
          (p_scope = 'MANUFACTURER' AND p.manufacturer_name = p_text_val) 
          OR
          -- [FIXED] Tìm kiếm linh hoạt trong cả Cabinet và Shelf
          (p_scope = 'CABINET' AND (
              inv.location_cabinet = p_text_val 
              OR inv.shelf_location = p_text_val
          ))
      );

    -- D. Cập nhật tổng tiền sổ sách (Total System Value)
    UPDATE public.inventory_checks 
    SET total_system_value = (
        SELECT COALESCE(SUM(system_quantity * cost_price), 0) 
        FROM public.inventory_check_items WHERE check_id = v_check_id
    )
    WHERE id = v_check_id;

    RETURN v_check_id;
END;
$function$
