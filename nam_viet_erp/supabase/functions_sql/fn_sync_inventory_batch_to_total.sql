CREATE OR REPLACE FUNCTION public.fn_sync_inventory_batch_to_total()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_product_id BIGINT;
    v_warehouse_id BIGINT;
    v_total_qty INTEGER;
BEGIN
    v_product_id := COALESCE(NEW.product_id, OLD.product_id);
    v_warehouse_id := COALESCE(NEW.warehouse_id, OLD.warehouse_id);

    -- Tính tổng các lô (Chỉ lấy lô dương để hiển thị an toàn, hoặc lấy tất cả tùy Sếp)
    -- Ở đây Core lấy SUM tất cả để trung thực với dữ liệu
    SELECT COALESCE(SUM(quantity), 0)
    INTO v_total_qty
    FROM public.inventory_batches
    WHERE product_id = v_product_id AND warehouse_id = v_warehouse_id;

    -- Update vào bảng tổng Product Inventory
    INSERT INTO public.product_inventory (product_id, warehouse_id, stock_quantity, updated_at)
    VALUES (v_product_id, v_warehouse_id, v_total_qty, NOW())
    ON CONFLICT (product_id, warehouse_id) 
    DO UPDATE SET 
        stock_quantity = EXCLUDED.stock_quantity,
        updated_at = NOW();

    RETURN NULL;
END;
$function$
