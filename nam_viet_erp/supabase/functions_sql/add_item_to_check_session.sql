CREATE OR REPLACE FUNCTION public.add_item_to_check_session(p_check_id bigint, p_product_id bigint)
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
    v_location text;
    v_pi_qty numeric;
    v_new_id bigint;
    v_batch record;
    v_has_batches boolean := false;
    v_inserted_ids bigint[] := ARRAY[]::bigint[];
    v_first_existing_id bigint;
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
            'message', 'Không thể thêm vào phiếu đã khóa/hủy'
        );
    END IF;

    SELECT COALESCE(actual_cost, 0)
    INTO v_cost_price
    FROM public.products
    WHERE id = p_product_id;

    SELECT
        COALESCE(stock_quantity, 0),
        (
            COALESCE(NULLIF(location_cabinet, '') || '-', '')
            || COALESCE(NULLIF(location_row, '') || '-', '')
            || COALESCE(location_slot, '')
        )
    INTO v_pi_qty, v_location
    FROM public.product_inventory
    WHERE warehouse_id = v_warehouse_id AND product_id = p_product_id;

    v_location := COALESCE(NULLIF(btrim(v_location), ''), 'Chưa xếp vị trí');
    v_pi_qty := COALESCE(v_pi_qty, 0);

    SELECT EXISTS (
        SELECT 1
        FROM public.inventory_batches ib
        WHERE ib.warehouse_id = v_warehouse_id
          AND ib.product_id = p_product_id
          AND ib.quantity > 0
    ) INTO v_has_batches;

    IF v_has_batches THEN
        IF EXISTS (
            SELECT 1
            FROM public.inventory_check_items ci
            WHERE ci.check_id = p_check_id
              AND ci.product_id = p_product_id
              AND (ci.batch_code IS NULL OR btrim(ci.batch_code) = '')
              AND (
                  COALESCE(ci.actual_quantity, 0) <> 0
                  OR ci.counted_at IS NOT NULL
              )
        ) THEN
            RETURN jsonb_build_object(
                'status', 'error',
                'message',
                'Sản phẩm đang có dòng kiểm kê tổng đã nhập số liệu. Xóa dòng đó trước khi thêm theo từng lô.'
            );
        END IF;

        DELETE FROM public.inventory_check_items ci
        WHERE ci.check_id = p_check_id
          AND ci.product_id = p_product_id
          AND (ci.batch_code IS NULL OR btrim(ci.batch_code) = '');

        FOR v_batch IN
            SELECT b.batch_code AS bc, b.expiry_date AS exp, ib.quantity AS qty
            FROM public.inventory_batches ib
            JOIN public.batches b ON ib.batch_id = b.id
            WHERE ib.warehouse_id = v_warehouse_id
              AND ib.product_id = p_product_id
              AND ib.quantity > 0
            ORDER BY b.expiry_date ASC NULLS LAST, b.id ASC
        LOOP
            IF EXISTS (
                SELECT 1
                FROM public.inventory_check_items x
                WHERE x.check_id = p_check_id
                  AND x.product_id = p_product_id
                  AND x.batch_code IS NOT DISTINCT FROM v_batch.bc
            ) THEN
                CONTINUE;
            END IF;

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
                v_batch.bc,
                v_batch.exp,
                LEAST(
                    GREATEST(v_batch.qty::integer, 0),
                    2147483647
                ),
                0,
                COALESCE(v_cost_price, 0),
                v_location,
                NOW(),
                NOW(),
                v_user_id,
                NULL,
                NULL
            )
            RETURNING id INTO v_new_id;

            v_inserted_ids := array_append(v_inserted_ids, v_new_id);
        END LOOP;

        IF cardinality(v_inserted_ids) > 0 THEN
            UPDATE public.inventory_checks SET updated_at = NOW() WHERE id = p_check_id;
            RETURN jsonb_build_object(
                'status', 'success',
                'item_id', v_inserted_ids[1],
                'item_ids', to_jsonb(v_inserted_ids),
                'inserted_count', cardinality(v_inserted_ids),
                'message', 'Đã thêm sản phẩm vào phiếu kiểm kê'
            );
        END IF;

        SELECT id INTO v_first_existing_id
        FROM public.inventory_check_items
        WHERE check_id = p_check_id AND product_id = p_product_id
        ORDER BY id ASC
        LIMIT 1;

        RETURN jsonb_build_object(
            'status', 'exists',
            'item_id', v_first_existing_id,
            'message', 'Tất cả lô của sản phẩm đã có trên phiếu'
        );
    END IF;

    -- Không có lô tồn > 0: một dòng tổng (hành vi cũ)
    SELECT id INTO v_first_existing_id
    FROM public.inventory_check_items
    WHERE check_id = p_check_id AND product_id = p_product_id
    LIMIT 1;

    IF v_first_existing_id IS NOT NULL THEN
        RETURN jsonb_build_object(
            'status', 'exists',
            'item_id', v_first_existing_id,
            'message', 'Sản phẩm này đã có trong phiếu'
        );
    END IF;

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
        LEAST(GREATEST(v_pi_qty::integer, 0), 2147483647),
        0,
        COALESCE(v_cost_price, 0),
        v_location,
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
        'item_id', v_new_id,
        'item_ids', jsonb_build_array(v_new_id),
        'inserted_count', 1,
        'message', 'Đã thêm sản phẩm vào phiếu kiểm kê'
    );
END;
$function$
