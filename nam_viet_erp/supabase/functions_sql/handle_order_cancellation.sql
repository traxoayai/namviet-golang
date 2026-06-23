CREATE OR REPLACE FUNCTION public.handle_order_cancellation(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_trans RECORD;
    BEGIN
        -- 1. Tìm tất cả các giao dịch xuất kho của đơn hàng này
        FOR v_trans IN 
            SELECT * FROM public.inventory_transactions 
            WHERE ref_id = (SELECT code FROM public.orders WHERE id = p_order_id)
              AND type = 'sale_order'
        LOOP
            -- 2. Cộng ngược lại vào kho (Inventory Batches)
            -- Lưu ý: v_trans.quantity là số âm (xuất kho), nên trừ đi số âm là cộng (-(-5) = +5)
            -- Hoặc đơn giản là lấy ABS()
            UPDATE public.inventory_batches
            SET quantity = quantity + ABS(v_trans.quantity), updated_at = NOW()
            WHERE warehouse_id = v_trans.warehouse_id
              AND product_id = v_trans.product_id
              AND batch_id = v_trans.batch_id;

            -- 3. Tạo Transaction bù trừ (Reversal Entry)
            INSERT INTO public.inventory_transactions (
                warehouse_id, product_id, batch_id, 
                type, action_group, quantity, unit_price, 
                ref_id, description, partner_id, created_by
            ) VALUES (
                v_trans.warehouse_id, v_trans.product_id, v_trans.batch_id,
                'import', 'RETURN', -- Type là Import để thể hiện hàng vào
                ABS(v_trans.quantity), v_trans.unit_price,
                v_trans.ref_id, 'Hoàn kho do hủy đơn ' || v_trans.ref_id, 
                v_trans.partner_id, auth.uid()
            );
        END LOOP;
    END;
    $function$
