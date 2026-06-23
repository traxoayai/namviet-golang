CREATE OR REPLACE FUNCTION public.bulk_update_batch_costs(p_changes jsonb, p_reason text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_user_id          UUID;
    v_change           JSONB;
    v_batch_id         BIGINT;
    v_new_price        NUMERIC;
    v_old_price        NUMERIC;
    v_product_id       BIGINT;
    v_qty_at_change    INTEGER;
    v_delta_per_unit   NUMERIC;
    v_ledger_total_qty NUMERIC;
    v_revaluation_id   BIGINT;
    v_revaluation_ids  BIGINT[] := ARRAY[]::BIGINT[];
    v_updated_count    INT := 0;
    v_skipped_count    INT := 0;
    v_vat_synced       BOOLEAN;
BEGIN
    -- 0. Auth & guard
    v_user_id := auth.uid();
    IF v_user_id IS NULL THEN
        RAISE EXCEPTION 'Unauthorized: chưa đăng nhập';
    END IF;

    IF p_reason IS NULL OR p_reason NOT IN ('data_fix','supplier_adjust','nrv_writedown') THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Thiếu hoặc sai reason_code. Hợp lệ: data_fix | supplier_adjust | nrv_writedown'
        );
    END IF;

    IF p_changes IS NULL OR jsonb_typeof(p_changes) <> 'array' OR jsonb_array_length(p_changes) = 0 THEN
        RETURN jsonb_build_object(
            'status', 'error',
            'message', 'Danh sách thay đổi rỗng'
        );
    END IF;

    -- 1. Loop từng change
    FOR v_change IN SELECT * FROM jsonb_array_elements(p_changes)
    LOOP
        v_batch_id  := (v_change->>'batch_id')::BIGINT;
        v_new_price := (v_change->>'new_price')::NUMERIC;

        IF v_batch_id IS NULL OR v_new_price IS NULL OR v_new_price < 0 THEN
            v_skipped_count := v_skipped_count + 1;
            CONTINUE;
        END IF;

        -- 1a. Lock row batches + lấy giá cũ + product_id
        SELECT b.inbound_price, b.product_id
          INTO v_old_price, v_product_id
        FROM public.batches b
        WHERE b.id = v_batch_id
        FOR UPDATE;

        IF NOT FOUND THEN
            v_skipped_count := v_skipped_count + 1;
            CONTINUE;
        END IF;

        v_old_price := COALESCE(v_old_price, 0);

        -- 1b. Skip nếu giá không đổi
        IF v_old_price = v_new_price THEN
            v_skipped_count := v_skipped_count + 1;
            CONTINUE;
        END IF;

        -- 1c. Tổng tồn của lô tại mọi kho (snapshot cho audit)
        SELECT COALESCE(SUM(ib.quantity), 0)::INTEGER
          INTO v_qty_at_change
        FROM public.inventory_batches ib
        WHERE ib.batch_id = v_batch_id;

        -- 1d. Sync vat_inventory_ledger nếu có dòng cho product đó
        v_vat_synced := false;

        SELECT COALESCE(SUM(l.quantity_balance), 0)
          INTO v_ledger_total_qty
        FROM public.vat_inventory_ledger l
        WHERE l.product_id = v_product_id AND l.quantity_balance > 0;

        IF v_ledger_total_qty > 0 AND v_qty_at_change > 0 THEN
            v_delta_per_unit := v_new_price - v_old_price;

            -- Phân bổ delta theo tỉ lệ qty từng vat_rate
            UPDATE public.vat_inventory_ledger l
            SET total_value_balance = l.total_value_balance
                                    + (v_qty_at_change * v_delta_per_unit)
                                      * (l.quantity_balance::NUMERIC / v_ledger_total_qty),
                updated_at = NOW()
            WHERE l.product_id = v_product_id
              AND l.quantity_balance > 0;

            v_vat_synced := true;
        END IF;

        -- 1e. INSERT audit
        INSERT INTO public.batch_revaluations (
            batch_id, product_id, warehouse_id,
            old_price, new_price, qty_at_change,
            reason_code, note, vat_synced, user_id
        ) VALUES (
            v_batch_id, v_product_id, NULL,
            v_old_price, v_new_price, v_qty_at_change,
            p_reason, p_note, v_vat_synced, v_user_id
        )
        RETURNING id INTO v_revaluation_id;

        v_revaluation_ids := array_append(v_revaluation_ids, v_revaluation_id);

        -- 1f. UPDATE giá mới
        UPDATE public.batches
        SET inbound_price = v_new_price
        WHERE id = v_batch_id;

        v_updated_count := v_updated_count + 1;
    END LOOP;

    RETURN jsonb_build_object(
        'status', 'success',
        'updated_count', v_updated_count,
        'skipped_count', v_skipped_count,
        'revaluation_ids', to_jsonb(v_revaluation_ids)
    );
END;
$function$
