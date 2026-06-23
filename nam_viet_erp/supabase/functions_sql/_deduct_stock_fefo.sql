CREATE OR REPLACE FUNCTION public._deduct_stock_fefo(p_warehouse_id bigint, p_product_id bigint, p_base_quantity numeric, p_unit_price numeric, p_order_code text, p_partner_id text DEFAULT NULL::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_remaining NUMERIC := p_base_quantity;
  v_deduct NUMERIC;
  v_batch RECORD;
BEGIN
  FOR v_batch IN
    SELECT ib.id, ib.warehouse_id, ib.quantity, ib.batch_id, b.batch_code
    FROM public.inventory_batches ib
    JOIN public.batches b ON ib.batch_id = b.id
    WHERE ib.product_id = p_product_id
      AND ib.quantity > 0
    ORDER BY b.expiry_date ASC, ib.id ASC
  LOOP
    IF v_remaining <= 0 THEN EXIT; END IF;
    v_deduct := LEAST(v_batch.quantity, v_remaining);

    UPDATE public.inventory_batches
    SET quantity = quantity - v_deduct, updated_at = NOW()
    WHERE id = v_batch.id;

    INSERT INTO public.inventory_transactions (
      warehouse_id, product_id, batch_id, partner_id,
      type, action_group, quantity, unit_price,
      ref_id, description, created_by, created_at
    ) VALUES (
      v_batch.warehouse_id, p_product_id, v_batch.batch_id, NULLIF(p_partner_id, '')::BIGINT,
      'out', 'sale', (v_deduct * -1), p_unit_price,
      p_order_code, 'Xuất bán (Lô: ' || v_batch.batch_code || ')',
      auth.uid(), NOW()
    );
    v_remaining := v_remaining - v_deduct;
  END LOOP;

  IF v_remaining > 0 THEN
    DECLARE
      v_pname TEXT;
      v_psku TEXT;
      v_punit TEXT;
      v_conv NUMERIC;
      v_missing NUMERIC;
    BEGIN
      -- Lookup thông tin sản phẩm và quy đổi sang đơn vị sỉ
      SELECT p.name, p.sku, p.wholesale_unit, pu.conversion_rate 
      INTO v_pname, v_psku, v_punit, v_conv
      FROM public.products p
      LEFT JOIN public.product_units pu ON pu.product_id = p.id AND pu.unit_name = p.wholesale_unit
      WHERE p.id = p_product_id;

      -- Tính số lượng thiếu theo đơn vị sỉ
      v_missing := ROUND(v_remaining / NULLIF(COALESCE(v_conv, 1), 0), 2);

      -- Raise exception với câu thông báo mới
      RAISE EXCEPTION 'Không đủ tồn kho cho SP % (SKU: %) sau khi trừ FEFO. Còn thiếu: % %',
        v_pname, v_psku, v_missing, COALESCE(v_punit, 'Đơn vị');
    END;
  END IF;
END;
$function$
