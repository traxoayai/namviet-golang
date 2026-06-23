CREATE OR REPLACE FUNCTION public.confirm_check_item_matching(p_item_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_item record;
    v_wh bigint;
    v_system_qty NUMERIC := 0;
BEGIN
    SELECT ci.*, ic.warehouse_id AS wh_id, ic.status AS check_status
    INTO v_item
    FROM public.inventory_check_items ci
    JOIN public.inventory_checks ic ON ic.id = ci.check_id
    WHERE ci.id = p_item_id;

    IF NOT FOUND THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Dòng kiểm kê không tồn tại');
    END IF;

    IF v_item.check_status IN ('COMPLETED', 'CANCELLED') THEN
        RETURN jsonb_build_object('status', 'error', 'message', 'Phiếu đã khóa/hủy');
    END IF;

    v_wh := v_item.wh_id;

    IF v_item.batch_code IS NOT NULL AND btrim(v_item.batch_code) <> '' THEN
        SELECT COALESCE(ib.quantity, 0) INTO v_system_qty
        FROM public.inventory_batches ib
        JOIN public.batches b ON ib.batch_id = b.id
        WHERE ib.warehouse_id = v_wh
          AND ib.product_id = v_item.product_id
          AND b.batch_code = v_item.batch_code
        LIMIT 1;
    ELSE
        SELECT COALESCE(SUM(ib.quantity), 0) INTO v_system_qty
        FROM public.inventory_batches ib
        WHERE ib.warehouse_id = v_wh
          AND ib.product_id = v_item.product_id;
    END IF;

    UPDATE public.inventory_check_items
    SET
        actual_quantity = v_system_qty,
        system_quantity = v_system_qty,
        updated_at = NOW(),
        counted_by = auth.uid(),
        counted_at = NOW()
    WHERE id = p_item_id;

    RETURN jsonb_build_object(
        'status', 'success',
        'message', 'Đã xác nhận khớp: ' || v_system_qty || ' ĐVCS',
        'actual_quantity', v_system_qty,
        'system_quantity', v_system_qty
    );
END;
$function$
