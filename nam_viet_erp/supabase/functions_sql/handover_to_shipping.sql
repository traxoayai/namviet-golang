CREATE OR REPLACE FUNCTION public.handover_to_shipping(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_current_status TEXT;
    BEGIN
        -- 1. Kiểm tra trạng thái
        SELECT status INTO v_current_status FROM public.orders WHERE id = p_order_id;

        IF v_current_status != 'PACKED' THEN
            RAISE EXCEPTION 'Đơn hàng chưa đóng gói xong (Phải là PACKED). Trạng thái hiện tại: %', v_current_status;
        END IF;

        -- 2. Update sang SHIPPING
        UPDATE public.orders
        SET status = 'SHIPPING',
            updated_at = NOW()
            -- Có thể thêm cột shipped_at vào bảng orders nếu cần thiết sau này
        WHERE id = p_order_id;

        RETURN jsonb_build_object(
            'success', true, 
            'message', 'Đã bàn giao cho đơn vị vận chuyển.'
        );
    END;
    $function$
