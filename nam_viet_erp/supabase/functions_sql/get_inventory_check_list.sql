CREATE OR REPLACE FUNCTION public.get_inventory_check_list(p_warehouse_id bigint)
 RETURNS TABLE(product_id bigint, product_name text, sku text, unit text, batch_code text, expiry_date date, system_quantity integer, cost_price numeric, location_cabinet text, location_row text, location_slot text, full_location text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        RETURN QUERY
        SELECT 
            p.id as product_id,
            p.name as product_name,
            p.sku,
            p.retail_unit as unit, -- Kiểm kê thường theo đơn vị nhỏ nhất
            
            -- Thông tin Lô (Từ bảng Inventory Batches)
            b.batch_code,
            b.expiry_date,
            ib.quantity as system_quantity,
            
            -- Giá vốn (Snapshot)
            p.actual_cost as cost_price,
            
            -- Vị trí (Từ bảng Product Inventory - Tổng)
            inv.location_cabinet,
            inv.location_row,
            inv.location_slot,
            inv.shelf_location as full_location

        FROM public.inventory_batches ib
        JOIN public.products p ON ib.product_id = p.id
        JOIN public.batches b ON ib.batch_id = b.id
        -- Join sang bảng tổng để lấy vị trí xếp hàng
        JOIN public.product_inventory inv ON ib.product_id = inv.product_id AND ib.warehouse_id = inv.warehouse_id

        WHERE ib.warehouse_id = p_warehouse_id
          AND ib.quantity > 0 -- Chỉ kiểm những lô máy báo còn tồn (Lô âm hoặc = 0 xử lý riêng)
        
        -- SẮP XẾP TỐI ƯU CHO NGƯỜI ĐI KIỂM
        ORDER BY 
            COALESCE(inv.location_cabinet, 'ZZZ'), -- Chưa xếp đi cuối
            COALESCE(inv.location_row, 'ZZZ'),
            COALESCE(inv.location_slot, 'ZZZ'),
            p.name ASC;
    END;
    $function$
