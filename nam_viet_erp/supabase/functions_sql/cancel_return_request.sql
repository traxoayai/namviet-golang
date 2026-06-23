CREATE OR REPLACE FUNCTION public.cancel_return_request(p_return_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_return RECORD; 
    v_item RECORD;
BEGIN
    SELECT * INTO v_return FROM public.sales_returns WHERE id = p_return_id FOR UPDATE;
    -- Chỉ cho phép hủy khi CHƯA nhập kho
    IF v_return.status != 'PENDING_INVENTORY' THEN 
        RAISE EXCEPTION 'Không thể hủy. Phiếu này đã được Kho hoặc Kế toán xử lý.'; 
    END IF;

    -- Hoàn trả lại số lượng "giữ chỗ" trong đơn hàng gốc
    FOR v_item IN SELECT order_item_id, quantity FROM public.sales_return_items WHERE return_id = p_return_id LOOP
        UPDATE public.order_items 
        SET quantity_returned = quantity_returned - v_item.quantity 
        WHERE id = v_item.order_item_id;
    END LOOP;

    UPDATE public.sales_returns SET status = 'CANCELLED', updated_at = NOW() WHERE id = p_return_id;
    RETURN jsonb_build_object('success', true, 'message', 'Đã hủy Yêu cầu trả hàng.');
END;
$function$
