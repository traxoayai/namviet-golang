CREATE OR REPLACE FUNCTION public.get_valid_vouchers_for_checkout(p_customer_id bigint, p_cart_total numeric DEFAULT 0)
 RETURNS TABLE(voucher_id bigint, code text, promo_name text, discount_type text, discount_value numeric, max_discount numeric, min_order_value numeric, is_eligible boolean, ineligibility_reason text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        RETURN QUERY
        SELECT 
            cv.id AS voucher_id,
            cv.code,
            p.name AS promo_name,
            p.discount_type,
            p.discount_value,
            p.max_discount_value AS max_discount, -- Giả định bảng promotions có cột này
            COALESCE(p.min_order_value, 0) AS min_order_value,
            
            -- Logic kiểm tra điều kiện (Eligible)
            CASE 
                -- Nếu tổng đơn nhỏ hơn mức tối thiểu -> False
                WHEN COALESCE(p.min_order_value, 0) > p_cart_total THEN FALSE
                ELSE TRUE
            END AS is_eligible,
            
            -- Tạo câu thông báo lý do (Human readable)
            CASE 
                WHEN COALESCE(p.min_order_value, 0) > p_cart_total THEN 
                    format('Đơn hàng cần tối thiểu %s đ', to_char(p.min_order_value, 'FM999,999,999'))
                ELSE NULL
            END AS ineligibility_reason

        FROM public.customer_vouchers cv
        JOIN public.promotions p ON cv.promotion_id = p.id
        WHERE 
            cv.customer_id = p_customer_id
            AND cv.status = 'active'
            AND (cv.usage_remaining IS NULL OR cv.usage_remaining > 0) -- Còn lượt dùng
            AND p.status = 'active' -- Chương trình còn chạy
            AND (p.valid_to IS NULL OR p.valid_to >= NOW()) -- Chưa hết hạn
            AND (p.valid_from <= NOW()); -- Đã bắt đầu
    END;
    $function$
