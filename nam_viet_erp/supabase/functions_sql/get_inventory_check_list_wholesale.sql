CREATE OR REPLACE FUNCTION public.get_inventory_check_list_wholesale(p_warehouse_id bigint)
 RETURNS TABLE(product_id bigint, product_name text, sku text, batch_code text, expiry_date date, base_quantity integer, stock_display text, location_cabinet text, location_row text, location_slot text, full_location text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id AS product_id,
        p.name AS product_name,
        p.sku,
        b.batch_code,
        b.expiry_date,
        ib.quantity AS base_quantity,

        -- [CORE LOGIC] BÓC TÁCH ĐƠN VỊ TÍNH
        COALESCE(
            NULLIF(
                CONCAT_WS(', ',
                    -- 1. Tính số Đơn vị Sỉ (Hộp)
                    CASE WHEN u_w.conversion_rate IS NOT NULL AND u_w.conversion_rate > 1 THEN
                        NULLIF(FLOOR(ib.quantity / u_w.conversion_rate)::int, 0) || ' ' || u_w.unit_name
                    ELSE NULL END,
                    
                    -- 2. Tính số Đơn vị Lẻ (Vỉ)
                    CASE WHEN u_w.conversion_rate IS NOT NULL AND u_r.conversion_rate IS NOT NULL AND u_r.conversion_rate > 1 THEN
                        NULLIF(FLOOR((ib.quantity % u_w.conversion_rate) / u_r.conversion_rate)::int, 0) || ' ' || u_r.unit_name
                    ELSE NULL END,
                    
                    -- 3. Tính số Đơn vị Cơ sở (Viên)
                    CASE 
                        WHEN u_w.conversion_rate IS NOT NULL AND u_r.conversion_rate IS NOT NULL AND u_r.conversion_rate > 1 THEN
                            NULLIF(((ib.quantity % u_w.conversion_rate) % u_r.conversion_rate)::int, 0) || ' ' || COALESCE(u_b.unit_name, p.retail_unit, 'Viên')
                        WHEN u_w.conversion_rate IS NOT NULL THEN
                            NULLIF((ib.quantity % u_w.conversion_rate)::int, 0) || ' ' || COALESCE(u_b.unit_name, p.retail_unit, 'Viên')
                        ELSE
                            ib.quantity || ' ' || COALESCE(u_b.unit_name, p.retail_unit, 'Viên')
                    END
                ), 
            ''), 
            '0 ' || COALESCE(u_b.unit_name, p.retail_unit, 'Viên') -- Fallback nếu quantity = 0
        ) AS stock_display,

        inv.location_cabinet,
        inv.location_row,
        inv.location_slot,
        inv.shelf_location AS full_location

    FROM public.inventory_batches ib
    JOIN public.products p ON ib.product_id = p.id
    JOIN public.batches b ON ib.batch_id = b.id
    LEFT JOIN public.product_inventory inv 
        ON ib.product_id = inv.product_id AND ib.warehouse_id = inv.warehouse_id
        
    -- [CORE] LATERAL JOIN để bóc tách 3 tầng đơn vị
    LEFT JOIN LATERAL (
        SELECT unit_name, conversion_rate FROM public.product_units 
        WHERE product_id = p.id AND unit_type = 'wholesale' LIMIT 1
    ) u_w ON true
    LEFT JOIN LATERAL (
        SELECT unit_name, conversion_rate FROM public.product_units 
        WHERE product_id = p.id AND unit_type = 'retail' LIMIT 1
    ) u_r ON true
    LEFT JOIN LATERAL (
        SELECT unit_name FROM public.product_units 
        WHERE product_id = p.id AND unit_type = 'base' LIMIT 1
    ) u_b ON true

    WHERE ib.warehouse_id = p_warehouse_id
      AND ib.quantity > 0 -- Chỉ lấy lô còn hàng
      AND p.status = 'active'
      
    -- Sắp xếp tối ưu lộ trình di chuyển trong kho
    ORDER BY 
        COALESCE(inv.location_cabinet, 'ZZZ') ASC,
        COALESCE(inv.location_row, 'ZZZ') ASC,
        COALESCE(inv.location_slot, 'ZZZ') ASC,
        p.name ASC, 
        b.expiry_date ASC;
END;
$function$
