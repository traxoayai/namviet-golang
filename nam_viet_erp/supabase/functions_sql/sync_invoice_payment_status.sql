CREATE OR REPLACE FUNCTION public.sync_invoice_payment_status()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    IF TG_TABLE_NAME = 'orders' THEN
        -- Đơn bán hàng (Sales) vẫn chạy bình thường vì map đúng kiểu UUID
        IF NEW.payment_status IS DISTINCT FROM OLD.payment_status OR NEW.paid_amount IS DISTINCT FROM OLD.paid_amount THEN
            UPDATE public.sales_invoices
            SET payment_status = NEW.payment_status,
                paid_amount = NEW.paid_amount
            WHERE order_id = NEW.id;
        END IF;
    ELSIF TG_TABLE_NAME = 'purchase_orders' THEN
        -- TẠM KHÓA ĐOẠN NÀY LẠI ĐỂ KHÔNG GÂY LỖI DUYỆT CHI
        -- Lý do: Bảng finance_invoices thiếu cột purchase_order_id (bigint)
        /*
        IF NEW.payment_status IS DISTINCT FROM OLD.payment_status OR NEW.total_paid IS DISTINCT FROM OLD.total_paid THEN
            UPDATE public.finance_invoices
            SET payment_status = NEW.payment_status,
                paid_amount = NEW.total_paid
            WHERE order_id = NEW.id;
        END IF;
        */
        NULL; -- Lệnh rỗng để bypass
    END IF;
    RETURN NEW;
END;
$function$
