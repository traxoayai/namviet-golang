CREATE OR REPLACE FUNCTION public._confirm_deduct_stock(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_code TEXT;
  v_warehouse_id BIGINT;
  v_partner_id TEXT;
  v_item RECORD;
  v_already_deducted BOOLEAN;
BEGIN
  SELECT code, warehouse_id, COALESCE(customer_id::TEXT, customer_b2c_id::TEXT)
  INTO v_code, v_warehouse_id, v_partner_id
  FROM public.orders WHERE id = p_order_id;

  IF v_code IS NULL OR v_warehouse_id IS NULL THEN RETURN; END IF;

  -- Idempotent guard: skip nếu đã có txn SALE cho đơn này
  SELECT EXISTS (
    SELECT 1 FROM public.inventory_transactions
    WHERE ref_id = v_code
      AND action_group IN ('sale', 'SALE')
      AND quantity < 0
      AND COALESCE(description, '') NOT LIKE '[REVERTED-DOUBLE-DEDUCT%'
  ) INTO v_already_deducted;

  IF v_already_deducted THEN RETURN; END IF;

  -- FEFO deduct từng item (throw exception nếu thiếu hàng)
  FOR v_item IN
    SELECT oi.product_id,
           (oi.quantity * COALESCE(oi.conversion_factor, 1))::NUMERIC AS base_qty,
           oi.unit_price
    FROM public.order_items oi
    WHERE oi.order_id = p_order_id
  LOOP
    PERFORM public._deduct_stock_fefo(
      v_warehouse_id, v_item.product_id, v_item.base_qty,
      v_item.unit_price, v_code, v_partner_id
    );
  END LOOP;
END;
$function$
