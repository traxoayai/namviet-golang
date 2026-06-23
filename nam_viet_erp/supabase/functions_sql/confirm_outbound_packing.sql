CREATE OR REPLACE FUNCTION public.confirm_outbound_packing(p_order_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_current_status TEXT;
  v_warehouse_id BIGINT;
  v_customer_id BIGINT;
  v_order_code TEXT;

  v_item RECORD;
  v_batch RECORD;
  v_qty_needed NUMERIC;
  v_deduct_amount NUMERIC;
  v_conversion_factor NUMERIC;

  v_agg_batch_no TEXT;
  v_min_expiry DATE;

  v_already_deducted BOOLEAN;
  v_lock_key BIGINT;
  v_has_any_deducted BOOLEAN := false;
BEGIN
  v_lock_key := ('x' || SUBSTRING(MD5(p_order_id::text), 1, 16))::bit(64)::BIGINT;
  PERFORM pg_advisory_xact_lock(v_lock_key);

  SELECT status, warehouse_id, code, customer_id
  INTO v_current_status, v_warehouse_id, v_order_code, v_customer_id
  FROM public.orders WHERE id = p_order_id;

  IF v_current_status IS NULL THEN
    RAISE EXCEPTION 'Không tìm thấy đơn hàng.';
  END IF;

  IF v_current_status != 'CONFIRMED' THEN
    RAISE EXCEPTION 'Đơn hàng không ở trạng thái chờ đóng gói (CONFIRMED).';
  END IF;

  IF v_warehouse_id IS NULL THEN
    v_warehouse_id := public.get_b2b_warehouse_id();
  END IF;

  FOR v_item IN
    SELECT oi.id AS order_item_id, oi.product_id, oi.quantity, oi.uom,
           oi.conversion_factor, p.name AS product_name, p.actual_cost
    FROM public.order_items oi
    JOIN public.products p ON oi.product_id = p.id
    WHERE oi.order_id = p_order_id
  LOOP
    v_conversion_factor := COALESCE(v_item.conversion_factor, 1);
    v_qty_needed := v_item.quantity * v_conversion_factor;

    v_agg_batch_no := NULL;
    v_min_expiry := NULL;

    -- [FIX CỰC KỲ QUAN TRỌNG]: Kiểm tra v_already_deducted cho TỪNG SẢN PHẨM MỘT
    SELECT EXISTS (
      SELECT 1 FROM public.inventory_transactions
      WHERE ref_id = v_order_code
        AND action_group IN ('sale', 'SALE')
        AND product_id = v_item.product_id
        AND quantity < 0
        AND COALESCE(description, '') NOT LIKE '[REVERTED-DOUBLE-DEDUCT%'
    ) INTO v_already_deducted;

    IF v_already_deducted THEN
      v_has_any_deducted := true;
      SELECT
        string_agg(DISTINCT b.batch_code, ', ' ORDER BY b.batch_code),
        MIN(b.expiry_date)
      INTO v_agg_batch_no, v_min_expiry
      FROM public.inventory_transactions it
      JOIN public.batches b ON b.id = it.batch_id
      WHERE it.ref_id = v_order_code
        AND it.action_group IN ('sale', 'SALE')
        AND it.product_id = v_item.product_id
        AND it.quantity < 0
        AND COALESCE(it.description, '') NOT LIKE '[REVERTED-DOUBLE-DEDUCT%';

    ELSE
      v_agg_batch_no := '';

      FOR v_batch IN
        SELECT ib.id, ib.batch_id, ib.quantity, b.inbound_price, b.batch_code, b.expiry_date
        FROM public.inventory_batches ib
        JOIN public.batches b ON ib.batch_id = b.id
        WHERE ib.product_id = v_item.product_id
          AND ib.warehouse_id = v_warehouse_id
          AND ib.quantity > 0
        ORDER BY b.expiry_date ASC, b.created_at ASC
        FOR UPDATE
      LOOP
        EXIT WHEN v_qty_needed <= 0;

        IF v_batch.quantity >= v_qty_needed THEN
          v_deduct_amount := v_qty_needed;
        ELSE
          v_deduct_amount := v_batch.quantity;
        END IF;

        UPDATE public.inventory_batches
        SET quantity = quantity - v_deduct_amount, updated_at = NOW()
        WHERE id = v_batch.id;

        INSERT INTO public.inventory_transactions (
          warehouse_id, product_id, batch_id,
          type, action_group,
          quantity, unit_price,
          ref_id, description, partner_id, created_at, created_by
        ) VALUES (
          v_warehouse_id, v_item.product_id, v_batch.batch_id,
          'sale_order', 'SALE',
          -v_deduct_amount, COALESCE(v_batch.inbound_price, v_item.actual_cost, 0),
          v_order_code, 'Xuất kho đơn ' || v_order_code, v_customer_id, NOW(), auth.uid()
        );

        IF v_agg_batch_no = '' THEN
          v_agg_batch_no := v_batch.batch_code;
          v_min_expiry := v_batch.expiry_date;
        ELSE
          v_agg_batch_no := v_agg_batch_no || ', ' || v_batch.batch_code;
          IF v_batch.expiry_date < v_min_expiry THEN
            v_min_expiry := v_batch.expiry_date;
          END IF;
        END IF;

        v_qty_needed := v_qty_needed - v_deduct_amount;
      END LOOP;

      IF v_qty_needed > 0 THEN
        RAISE EXCEPTION 'Kho không đủ hàng xuất cho sản phẩm "%". Thiếu % (đvcs). Vui lòng kiểm tra tồn kho.',
          v_item.product_name, v_qty_needed;
      END IF;
    END IF;

    UPDATE public.order_items
    SET
      quantity_picked = (v_item.quantity * v_conversion_factor),
      batch_no = COALESCE(NULLIF(v_agg_batch_no, ''), batch_no),
      expiry_date = COALESCE(v_min_expiry, expiry_date)
    WHERE id = v_item.order_item_id;

  END LOOP;

  UPDATE public.orders
  SET status = 'PACKED', updated_at = NOW()
  WHERE id = p_order_id;

  RETURN jsonb_build_object(
    'success', true,
    'already_deducted', v_has_any_deducted,
    'message', CASE
      WHEN v_has_any_deducted THEN 'Đã đóng gói (một số mã đã được trừ kho từ trước).'
      ELSE 'Đã xuất kho và đóng gói thành công.'
    END
  );
END;
$function$
