CREATE OR REPLACE FUNCTION public.update_outbound_package_count(p_order_id uuid, p_count integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        IF p_count < 1 THEN
            RAISE EXCEPTION 'Số kiện hàng phải lớn hơn hoặc bằng 1.';
        END IF;

        UPDATE public.orders
        SET package_count = p_count,
            updated_at = NOW()
        WHERE id = p_order_id;

        RETURN jsonb_build_object('success', true, 'message', 'Đã cập nhật số kiện hàng.');
    END;
    $function$
