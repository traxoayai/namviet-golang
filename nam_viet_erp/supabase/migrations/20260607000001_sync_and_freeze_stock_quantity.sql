-- Migration: Sync and Freeze stock_quantity

-- 1. Xóa các trigger cũ nếu có để tránh xung đột
DROP TRIGGER IF EXISTS trg_sync_product_inventory ON public.inventory_batches;
DROP TRIGGER IF EXISTS trg_freeze_stock_quantity ON public.product_inventory;

-- 2. Chữa cháy: Cập nhật lại số lượng đúng từ bảng lô/hạn
UPDATE public.product_inventory pi
SET stock_quantity = COALESCE(batch_sum.total, 0),
    updated_at = NOW()
FROM (
    SELECT product_id, warehouse_id, SUM(quantity) as total
    FROM public.inventory_batches
    GROUP BY product_id, warehouse_id
) batch_sum
WHERE pi.product_id = batch_sum.product_id
  AND pi.warehouse_id = batch_sum.warehouse_id;

-- Reset những dòng không có lô nào về 0
UPDATE public.product_inventory pi
SET stock_quantity = 0,
    updated_at = NOW()
WHERE NOT EXISTS (
    SELECT 1 
    FROM public.inventory_batches ib 
    WHERE ib.product_id = pi.product_id 
      AND ib.warehouse_id = pi.warehouse_id
) AND pi.stock_quantity != 0;

-- 3. Xử lý tồn kho âm hiện tại (Ép về 0) để không vi phạm ràng buộc
UPDATE public.inventory_batches SET quantity = 0 WHERE quantity < 0;
UPDATE public.product_inventory SET stock_quantity = 0 WHERE stock_quantity < 0;

-- 4. Thêm Constraint chặn bán âm
ALTER TABLE public.inventory_batches DROP CONSTRAINT IF EXISTS inventory_batches_quantity_check;
ALTER TABLE public.inventory_batches ADD CONSTRAINT inventory_batches_quantity_check CHECK (quantity >= 0);

ALTER TABLE public.product_inventory DROP CONSTRAINT IF EXISTS product_inventory_stock_quantity_check;
ALTER TABLE public.product_inventory ADD CONSTRAINT product_inventory_stock_quantity_check CHECK (stock_quantity >= 0);

-- 5. Đóng băng API cập nhật trực tiếp vào product_inventory.stock_quantity
CREATE OR REPLACE FUNCTION public.freeze_stock_quantity_update()
RETURNS TRIGGER AS $$
BEGIN
    -- Chỉ cho phép thay đổi nếu biến session 'inventory.syncing' được bật bởi Trigger phía dưới
    IF current_setting('inventory.syncing', true) IS DISTINCT FROM 'true' THEN
        NEW.stock_quantity = OLD.stock_quantity;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_freeze_stock_quantity
BEFORE UPDATE OF stock_quantity ON public.product_inventory
FOR EACH ROW
EXECUTE FUNCTION public.freeze_stock_quantity_update();

-- 6. Tạo Trigger Đồng bộ tự động từ inventory_batches -> product_inventory
CREATE OR REPLACE FUNCTION public.sync_product_inventory_from_batches()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_product_inventory
AFTER INSERT OR UPDATE OF quantity, product_id, warehouse_id OR DELETE
ON public.inventory_batches
FOR EACH ROW
EXECUTE FUNCTION public.sync_product_inventory_from_batches();
