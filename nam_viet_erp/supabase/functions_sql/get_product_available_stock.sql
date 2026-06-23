CREATE OR REPLACE FUNCTION public.get_product_available_stock(p_warehouse_id bigint, p_product_ids bigint[])
 RETURNS TABLE(product_id bigint, real_stock integer, committed_stock integer, available_stock integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        RETURN QUERY
        WITH real_inv AS (
            -- Lấy tồn kho thực tế
            SELECT pi.product_id, pi.stock_quantity
            FROM public.product_inventory pi
            WHERE pi.warehouse_id = p_warehouse_id 
              AND pi.product_id = ANY(p_product_ids)
        ),
        committed_inv AS (
            -- Tính hàng đang bị giữ (Chỉ tính đơn CONFIRMED)
            SELECT oi.product_id, SUM(oi.quantity * COALESCE(oi.conversion_factor, 1))::INT as qty_held
            FROM public.order_items oi
            JOIN public.orders o ON oi.order_id = o.id
            WHERE o.warehouse_id = p_warehouse_id
              AND o.status = 'CONFIRMED' -- [CORE FIXED]: Chỉ trừ CONFIRMED
              AND oi.product_id = ANY(p_product_ids)
            GROUP BY oi.product_id
        )
        SELECT 
            id as product_id,
            COALESCE(r.stock_quantity, 0) as real_stock,
            COALESCE(c.qty_held, 0) as committed_stock,
            (COALESCE(r.stock_quantity, 0) - COALESCE(c.qty_held, 0)) as available_stock
        FROM unnest(p_product_ids) as id
        LEFT JOIN real_inv r ON r.product_id = id
        LEFT JOIN committed_inv c ON c.product_id = id;
    END;
    $function$
