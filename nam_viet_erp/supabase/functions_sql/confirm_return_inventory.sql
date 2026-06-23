CREATE OR REPLACE FUNCTION public.confirm_return_inventory(p_return_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_return RECORD; 
    v_item RECORD; 
    v_order RECORD; 
    v_batch_id BIGINT; 
    v_qty_base INTEGER;
BEGIN
    SELECT * INTO v_return FROM public.sales_returns WHERE id = p_return_id FOR UPDATE;
    IF v_return.status != 'PENDING_INVENTORY' THEN RAISE EXCEPTION 'Phiếu trả này không ở trạng thái Chờ nhập kho.'; END IF;
    
    SELECT * INTO v_order FROM public.orders WHERE id = v_return.order_id;

    FOR v_item IN SELECT * FROM public.sales_return_items WHERE return_id = p_return_id LOOP
        -- Lấy tỷ lệ quy đổi từ đơn gốc để nhập đúng Base Unit
        v_qty_base := v_item.quantity * COALESCE((SELECT conversion_factor FROM public.order_items WHERE id = v_item.order_item_id), 1);

        -- Sinh lô ảo
        INSERT INTO public.batches (product_id, batch_code, expiry_date, inbound_price, created_at)
        VALUES (v_item.product_id, 'RET-' || v_return.code, '2099-12-31'::DATE, 0, NOW()) RETURNING id INTO v_batch_id;

        -- Nhập kho (Trigger tổng sẽ tự chạy)
        INSERT INTO public.inventory_batches (warehouse_id, product_id, batch_id, quantity, updated_at)
        VALUES (v_item.warehouse_id, v_item.product_id, v_batch_id, v_qty_base, NOW());

        -- Ghi thẻ kho
        INSERT INTO public.inventory_transactions (warehouse_id, product_id, batch_id, type, action_group, quantity, unit_price, ref_id, description, created_by) 
        VALUES (v_item.warehouse_id, v_item.product_id, v_batch_id, 'return_in', 'RETURN', v_qty_base, 0, v_return.code, 'Nhập kho hàng trả (Đơn ' || v_order.code || ')', auth.uid());
    END LOOP;

    UPDATE public.sales_returns SET status = 'PENDING_REFUND', updated_at = NOW() WHERE id = p_return_id;

    RETURN jsonb_build_object('success', true, 'message', 'Đã nhập kho thành công. Chờ Kế toán hoàn tiền.');
END;
$function$
