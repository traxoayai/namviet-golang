CREATE OR REPLACE FUNCTION public.notify_sales_on_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_sales_staff_id UUID;
    v_partner_name TEXT;
BEGIN
    -- Khi phiếu thu hoàn tất
    IF NEW.flow = 'in' 
       AND NEW.status = 'completed' 
       AND (OLD.status IS NULL OR OLD.status != 'completed') 
    THEN
        
        -- Tìm Sales phụ trách khách hàng này (Chỉ áp dụng B2B)
        IF NEW.partner_type = 'customer_b2b' THEN
            -- Lấy Sales ID và Tên khách
            SELECT sales_staff_id, name INTO v_sales_staff_id, v_partner_name
            FROM public.customers_b2b 
            WHERE id = NEW.partner_id::BIGINT;

            -- Gửi thông báo nếu có Sales phụ trách
            IF v_sales_staff_id IS NOT NULL THEN
                INSERT INTO public.notifications (user_id, title, message, type, is_read, created_at)
                VALUES (
                    v_sales_staff_id,
                    'Tiền về! 💰',
                    'Khách hàng ' || COALESCE(v_partner_name, 'B2B') || ' vừa thanh toán ' || to_char(NEW.amount, 'FM999,999,999') || 'đ.',
                    'success',
                    false,
                    NOW()
                );
            END IF;
        END IF;
    END IF;
    RETURN NEW;
END;
$function$
