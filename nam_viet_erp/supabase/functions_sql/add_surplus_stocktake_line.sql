CREATE OR REPLACE FUNCTION public.add_surplus_stocktake_line(p_check_id bigint, p_product_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_warehouse_id bigint;
    v_check_status text;
    v_user_id uuid;
    v_cost_price numeric;
    v_new_id bigint;
BEGIN
    v_user_id := auth.uid();

    SELECT warehouse_id, status
    INTO v_warehouse_id, v_check_status
    FROM public.inventory_checks
    WHERE id = p_check_id;

    IF v_warehouse_id IS NULL THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Phiếu kiểm kê không tồn tại'
        );
    END IF;

    IF v_check_status IN ('COMPLETED', 'CANCELLED') THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Không thể thêm dòng vào phiếu đã khóa/hủy'
        );
    END IF;

    IF NOT EXISTS (SELECT 1 FROM public.products WHERE id = p_product_id) THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Sản phẩm không tồn tại'
        );
    END IF;

    SELECT COALESCE(actual_cost, 0) INTO v_cost_price
    FROM public.products
    WHERE id = p_product_id;

    INSERT INTO public.inventory_check_items (
        check_id,
        product_id,
        batch_code,
        expiry_date,
        system_quantity,
        actual_quantity,
        cost_price,
        location_snapshot,
        created_at,
        updated_at,
        created_by,
        counted_by,
        counted_at
    ) VALUES (
        p_check_id,
        p_product_id,
        NULL,
        NULL,
        0,
        0,
        COALESCE(v_cost_price, 0),
        'Thừa hàng / lô mới (nhập số lô khi đếm)',
        NOW(),
        NOW(),
        v_user_id,
        NULL,
        NULL
    )
    RETURNING id INTO v_new_id;

    UPDATE public.inventory_checks SET updated_at = NOW() WHERE id = p_check_id;

    RETURN jsonb_build_object(
        'status', 'success',
        'id', v_new_id,
        'item_id', v_new_id,
        'message', 'Đã thêm dòng thừa hàng — nhập số lô và số lượng thực tế'
    );
END;
$function$
