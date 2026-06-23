CREATE OR REPLACE FUNCTION public.sync_product_inventory_from_batches()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Bật biến session để báo hiệu cho Freeze Trigger bỏ qua khóa
    PERFORM set_config('inventory.syncing', 'true', true);

    IF TG_OP = 'DELETE' THEN
        UPDATE public.product_inventory
        SET stock_quantity = COALESCE((SELECT SUM(quantity) FROM public.inventory_batches WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id), 0),
            updated_at = NOW()
        WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Tính lại kho cũ nếu chuyển kho hoặc chuyển sản phẩm
        IF OLD.product_id != NEW.product_id OR OLD.warehouse_id != NEW.warehouse_id THEN
            UPDATE public.product_inventory
            SET stock_quantity = COALESCE((SELECT SUM(quantity) FROM public.inventory_batches WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id), 0),
                updated_at = NOW()
            WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id;
        END IF;
        
        -- Tính lại kho mới
        UPDATE public.product_inventory
        SET stock_quantity = COALESCE((SELECT SUM(quantity) FROM public.inventory_batches WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id), 0),
            updated_at = NOW()
        WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        UPDATE public.product_inventory
        SET stock_quantity = COALESCE((SELECT SUM(quantity) FROM public.inventory_batches WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id), 0),
            updated_at = NOW()
        WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$function$
