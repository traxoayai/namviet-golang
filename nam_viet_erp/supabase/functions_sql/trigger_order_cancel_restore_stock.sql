CREATE OR REPLACE FUNCTION public.trigger_order_cancel_restore_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
    BEGIN
        -- Khi đơn chuyển sang CANCELLED và trước đó đã PACKED/SHIPPING/DELIVERED (đã trừ kho)
        IF NEW.status = 'CANCELLED' AND OLD.status IN ('PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED') THEN
            PERFORM public.handle_order_cancellation(NEW.id);
        END IF;
        RETURN NEW;
    END;
    $function$
