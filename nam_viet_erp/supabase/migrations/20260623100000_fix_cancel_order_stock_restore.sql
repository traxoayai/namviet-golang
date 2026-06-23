CREATE OR REPLACE FUNCTION public.handle_order_cancellation(p_order_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_trans RECORD;
    v_order_code TEXT;
BEGIN
    SELECT code INTO v_order_code FROM public.orders WHERE id = p_order_id;

    -- Tìm tất cả các giao dịch xuất kho của đơn hàng này chưa bị hoàn trả
    -- Chỉ tìm các giao dịch trừ kho thực sự (số lượng âm)
    FOR v_trans IN 
        SELECT * FROM public.inventory_transactions 
        WHERE ref_id = v_order_code 
          AND type = 'sale_order'
          AND quantity < 0
    LOOP
        -- 1. Cộng trả lại bảng Lô (inventory_batches) đúng kho, đúng lô, đúng số lượng
        -- LƯU Ý: v_trans.quantity đang là số âm (VD: -5). ABS(-5) = 5
        UPDATE public.inventory_batches
        SET quantity = quantity + ABS(v_trans.quantity), updated_at = NOW()
        WHERE warehouse_id = v_trans.warehouse_id
          AND product_id = v_trans.product_id
          AND batch_id = v_trans.batch_id;

        -- 2. Cộng trả lại bảng Tổng tồn kho (product_inventory) - ĐÂY LÀ CHỖ LỖI CŨ BỊ THIẾU
        UPDATE public.product_inventory
        SET stock_quantity = stock_quantity + ABS(v_trans.quantity), updated_at = NOW()
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
            ABS(v_trans.quantity), v_trans.unit_price,
            v_trans.ref_id, 'Hoàn kho do hủy đơn ' || v_trans.ref_id, 
            v_trans.partner_id, auth.uid()
        );
    END LOOP;
END;
$function$;


CREATE OR REPLACE FUNCTION public.trigger_order_cancel_restore_stock()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- [FIX 2026-06-23]: Gọi LUÔN hàm hoàn trả kho khi đơn hàng chuyển sang CANCELLED
    -- Thay vì hardcode OLD.status IN ('PACKED',...), ta gọi handle_order_cancellation
    -- Hàm kia đã xử lý an toàn: chỉ hoàn kho nếu THỰC SỰ có lịch sử xuất kho trong inventory_transactions
    IF NEW.status = 'CANCELLED' AND OLD.status != 'CANCELLED' THEN
        PERFORM public.handle_order_cancellation(NEW.id);
    END IF;
    RETURN NEW;
END;
$function$;


CREATE OR REPLACE FUNCTION public.cancel_order(
    p_order_id uuid,
    p_reason text DEFAULT 'Hủy theo yêu cầu'::text,
    p_user_id uuid DEFAULT auth.uid()
) RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_order RECORD;
    v_user_name TEXT;
BEGIN
    -- 1. Lấy và khóa đơn hàng
    SELECT * INTO v_order FROM public.orders WHERE id = p_order_id FOR UPDATE;

    IF v_order IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy đơn hàng.';
    END IF;

    -- 2. Validate trạng thái
    IF v_order.status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Đơn hàng này đã bị hủy từ trước.';
    END IF;

    -- KHÔNG cho phép hủy ngang đơn đã giao/hoàn tất.
    IF v_order.status IN ('DELIVERED', 'COMPLETED') THEN
        RAISE EXCEPTION 'Đơn hàng đã giao thành công. Vui lòng sử dụng tính năng Trả Hàng thay vì Hủy Đơn.';
    END IF;

    -- 3. Lấy tên người hủy
    SELECT COALESCE(full_name, email, 'Hệ thống') INTO v_user_name 
    FROM public.users WHERE id = COALESCE(p_user_id, auth.uid());

    -- 4. THỰC THI HỦY
    -- Khi update thành 'CANCELLED', PostgreSQL sẽ tự động đánh thức:
    -- + trigger_order_cancel_restore_stock: Đã được sửa để tự động hoàn trả đúng kho, lô, số lượng.
    -- + trg_update_debt_from_orders: Trừ lại công nợ
    UPDATE public.orders
    SET status = 'CANCELLED',
        note = COALESCE(note, '') || E'\n--- \n[HỦY ĐƠN ' || TO_CHAR(NOW(), 'DD/MM/YYYY HH24:MI') || '] - Người hủy: ' || v_user_name || ' - Lý do: ' || p_reason,
        updated_at = NOW()
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã hủy đơn hàng thành công! Hệ thống đã tự động hoàn trả đầy đủ Kho và Công nợ.'
    );
END;
$function$;
