CREATE OR REPLACE FUNCTION public.trigger_order_cancel_restore_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- [FIX 2026-06-23]: Gọi LUÔN hàm hoàn trả kho khi đơn hàng chuyển sang CANCELLED
    -- Thay vì hardcode OLD.status IN ('PACKED',...), ta gọi handle_order_cancellation
    -- Hàm kia đã xử lý an toàn: chỉ hoàn kho nếu THỰC SỰ có lịch sử xuất kho trong inventory_transactions
    IF NEW.status = 'CANCELLED' AND OLD.status != 'CANCELLED' THEN
        PERFORM public.handle_order_cancellation(NEW.id);
    END IF;
    RETURN NEW;
END;
$function$
