CREATE OR REPLACE FUNCTION public.get_outbound_stats(p_warehouse_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_pending_packing INT;
        v_shipping INT;
        v_completed_today INT;
    BEGIN
        -- 1. Chờ đóng gói (CONFIRMED)
        SELECT COUNT(*) INTO v_pending_packing
        FROM public.orders
        WHERE status = 'CONFIRMED';

        -- 2. Đang giao hàng (SHIPPING)
        SELECT COUNT(*) INTO v_shipping
        FROM public.orders
        WHERE status = 'SHIPPING';

        -- 3. Hoàn thành hôm nay (DELIVERED & Updated hôm nay)
        SELECT COUNT(*) INTO v_completed_today
        FROM public.orders
        WHERE status = 'DELIVERED'
          AND updated_at >= date_trunc('day', now());

        RETURN jsonb_build_object(
            'pending_packing', v_pending_packing,
            'shipping', v_shipping,
            'completed_today', v_completed_today
        );
    END;
    $function$
