CREATE OR REPLACE FUNCTION public.freeze_stock_quantity_update()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Chỉ cho phép thay đổi nếu biến session 'inventory.syncing' được bật bởi Trigger phía dưới
    IF current_setting('inventory.syncing', true) IS DISTINCT FROM 'true' THEN
        NEW.stock_quantity = OLD.stock_quantity;
    END IF;
    RETURN NEW;
END;
$function$
