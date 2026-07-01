CREATE OR REPLACE FUNCTION public.handle_order_cancellation(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_trans RECORD;
    v_order_code TEXT;
    v_already_restocked BOOLEAN;
BEGIN
    SELECT code INTO v_order_code FROM public.orders WHERE id = p_order_id;
    IF v_order_code IS NULL THEN RETURN; END IF;

    -- Idempotent guard: Tránh cộng đúp kho nếu đã có giao dịch RETURN
    SELECT EXISTS (
        SELECT 1 FROM public.inventory_transactions
        WHERE ref_id = v_order_code
          AND action_group = 'RETURN'
          AND quantity > 0
    ) INTO v_already_restocked;

    IF v_already_restocked THEN 
        RETURN; 
    END IF;

    -- Tìm tất cả các giao dịch xuất kho của đơn hàng này chưa bị hoàn trả
    -- Chỉ tìm các giao dịch trừ kho thực sự (số lượng âm)
    FOR v_trans IN 
        SELECT warehouse_id, product_id, batch_id,
               SUM(ABS(quantity))::NUMERIC AS total_deducted,
               MAX(unit_price) AS unit_price,
               MAX(partner_id) AS partner_id
        FROM public.inventory_transactions 
        WHERE ref_id = v_order_code 
          AND (type = 'sale_order' OR action_group IN ('sale', 'SALE'))
          AND quantity < 0
          AND COALESCE(description, '') NOT LIKE '[REVERTED-DOUBLE-DEDUCT%'
        GROUP BY warehouse_id, product_id, batch_id
        HAVING SUM(ABS(quantity)) > 0
    LOOP
        -- 1. Cộng trả lại bảng Lô (inventory_batches) đúng kho, đúng lô, đúng số lượng
        UPDATE public.inventory_batches
        SET quantity = quantity + v_trans.total_deducted, updated_at = NOW()
        WHERE warehouse_id = v_trans.warehouse_id
          AND product_id = v_trans.product_id
          AND batch_id = v_trans.batch_id;

        -- 2. Cộng trả lại bảng Tổng tồn kho (product_inventory)
        UPDATE public.product_inventory
        SET stock_quantity = stock_quantity + v_trans.total_deducted, updated_at = NOW()
        WHERE warehouse_id = v_trans.warehouse_id
          AND product_id = v_trans.product_id;

        -- 3. Tạo Transaction bù trừ (Reversal Entry)
        INSERT INTO public.inventory_transactions (
            warehouse_id, product_id, batch_id, 
            type, action_group, quantity, unit_price, 
            ref_id, description, partner_id, created_by
        ) VALUES (
            v_trans.warehouse_id, v_trans.product_id, v_trans.batch_id,
            'import', 'RETURN', 
            v_trans.total_deducted, v_trans.unit_price,
            v_order_code, 'Hoàn kho do hủy đơn ' || v_order_code, 
            v_trans.partner_id, auth.uid()
        );
    END LOOP;
END;
$function$
