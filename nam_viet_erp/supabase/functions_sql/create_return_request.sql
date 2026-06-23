CREATE OR REPLACE FUNCTION public.create_return_request(p_payload jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_order_id UUID; 
    v_order RECORD; 
    v_return_id UUID; 
    v_return_code TEXT;
    v_item JSONB; 
    v_order_item RECORD; 
    v_total_refund NUMERIC := 0; 
    v_qty_return INTEGER;
BEGIN
    v_order_id := (p_payload->>'order_id')::UUID;
    SELECT * INTO v_order FROM public.orders WHERE id = v_order_id FOR UPDATE;
    IF v_order IS NULL THEN RAISE EXCEPTION 'Không tìm thấy đơn hàng.'; END IF;

    v_return_code := public._gen_finance_tx_code('RET');

    -- Tạo Header ở trạng thái CHỜ KHO
    INSERT INTO public.sales_returns (code, order_id, customer_id, customer_b2c_id, status, note, created_by)
    VALUES (v_return_code, v_order_id, v_order.customer_id, v_order.customer_b2c_id, 'PENDING_INVENTORY', p_payload->>'note', auth.uid())
    RETURNING id INTO v_return_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_payload->'items') LOOP
        v_qty_return := (v_item->>'quantity')::INTEGER;
        IF v_qty_return <= 0 THEN CONTINUE; END IF;

        SELECT * INTO v_order_item FROM public.order_items WHERE id = (v_item->>'order_item_id')::UUID FOR UPDATE;
        IF (COALESCE(v_order_item.quantity_returned, 0) + v_qty_return) > v_order_item.quantity THEN
            RAISE EXCEPTION 'Số lượng trả của sản phẩm ID % vượt quá số lượng mua.', v_order_item.product_id;
        END IF;

        -- Khóa số lượng trả trong đơn gốc (giữ chỗ)
        UPDATE public.order_items SET quantity_returned = COALESCE(quantity_returned, 0) + v_qty_return WHERE id = v_order_item.id;

        INSERT INTO public.sales_return_items (return_id, order_item_id, product_id, quantity, refund_price, warehouse_id)
        VALUES (v_return_id, v_order_item.id, v_order_item.product_id, v_qty_return, (v_item->>'refund_price')::NUMERIC, (v_item->>'warehouse_id')::BIGINT);

        v_total_refund := v_total_refund + (v_qty_return * (v_item->>'refund_price')::NUMERIC);
    END LOOP;

    UPDATE public.sales_returns SET total_refund_amount = v_total_refund WHERE id = v_return_id;

    RETURN jsonb_build_object('success', true, 'message', 'Đã tạo Yêu cầu trả hàng. Chờ Thủ kho xác nhận!', 'return_id', v_return_id);
END;
$function$
