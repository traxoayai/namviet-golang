CREATE OR REPLACE FUNCTION public.sync_order_remittance_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- TRƯỜNG HỢP 1: THỦ QUỸ DUYỆT (Pending -> Completed)
        -- Tiền chính thức vào sổ quỹ -> Đơn hàng đổi thành 'deposited'
        IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
            
            UPDATE public.orders
            SET 
                remittance_status = 'deposited', -- Đã nộp xong
                updated_at = NOW()
            WHERE remittance_transaction_id = NEW.id;
            
        -- TRƯỜNG HỢP 2: THỦ QUỸ TỪ CHỐI (Pending -> Cancelled)
        -- Trả đơn hàng về trạng thái 'pending' để nhân viên nộp lại
        ELSIF NEW.status = 'cancelled' AND OLD.status != 'cancelled' THEN
            
            UPDATE public.orders
            SET 
                remittance_status = 'pending',       -- Quay lại chờ nộp
                remittance_transaction_id = NULL,    -- Gỡ liên kết phiếu thu bị hủy
                updated_at = NOW()
            WHERE remittance_transaction_id = NEW.id;
            
        END IF;

        RETURN NEW;
    END;
    $function$
