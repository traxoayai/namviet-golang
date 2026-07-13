-- Migration: Fix Concurrency Lost Update in inventory_batches trigger
-- Replaces aggregate SUM() with Delta updates to guarantee consistency under Read Committed isolation.

CREATE OR REPLACE FUNCTION public.sync_product_inventory_from_batches()
RETURNS TRIGGER AS $$
BEGIN
    -- Bật biến session để báo hiệu cho Freeze Trigger bỏ qua khóa
    PERFORM set_config('inventory.syncing', 'true', true);

    IF TG_OP = 'DELETE' THEN
        UPDATE public.product_inventory
        SET stock_quantity = COALESCE(stock_quantity, 0) - OLD.quantity,
            updated_at = NOW()
        WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id;
        RETURN OLD;
    ELSIF TG_OP = 'UPDATE' THEN
        -- Nếu đổi sang lô của kho khác hoặc sản phẩm khác (hiếm khi xảy ra)
        IF OLD.product_id != NEW.product_id OR OLD.warehouse_id != NEW.warehouse_id THEN
            -- Trừ lượng của kho cũ
            UPDATE public.product_inventory
            SET stock_quantity = COALESCE(stock_quantity, 0) - OLD.quantity,
                updated_at = NOW()
            WHERE product_id = OLD.product_id AND warehouse_id = OLD.warehouse_id;
            
            -- Cộng lượng cho kho mới
            UPDATE public.product_inventory
            SET stock_quantity = COALESCE(stock_quantity, 0) + NEW.quantity,
                updated_at = NOW()
            WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
        ELSE
            -- Cùng kho, cùng sản phẩm: Update bằng ĐỘ LỆCH (Delta).
            -- Cách này đảm bảo không bị ghi đè (lost updates) khi nhiều người thao tác cùng lúc
            UPDATE public.product_inventory
            SET stock_quantity = COALESCE(stock_quantity, 0) + (NEW.quantity - OLD.quantity),
                updated_at = NOW()
            WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'INSERT' THEN
        UPDATE public.product_inventory
        SET stock_quantity = COALESCE(stock_quantity, 0) + NEW.quantity,
            updated_at = NOW()
        WHERE product_id = NEW.product_id AND warehouse_id = NEW.warehouse_id;
        RETURN NEW;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;
