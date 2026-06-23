CREATE OR REPLACE FUNCTION public.cancel_order(p_order_id uuid, p_reason text DEFAULT 'Hủy theo yêu cầu'::text, p_user_id uuid DEFAULT auth.uid())
 RETURNS jsonb
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

    -- KHÔNG cho phép hủy ngang đơn đã giao/hoàn tất. (Nghiệp vụ kế toán: Đã giao thì phải làm Phiếu Trả Hàng)
    IF v_order.status IN ('DELIVERED', 'COMPLETED') THEN
        RAISE EXCEPTION 'Đơn hàng đã giao thành công. Vui lòng sử dụng tính năng Trả Hàng thay vì Hủy Đơn.';
    END IF;

    -- 3. Lấy tên người hủy để ghi vào note
    SELECT COALESCE(full_name, email, 'Hệ thống') INTO v_user_name 
    FROM public.users WHERE id = COALESCE(p_user_id, auth.uid());

    -- 4. THỰC THI HỦY (PHÉP MÀU NẰM Ở ĐÂY)
    -- Khi update thành 'CANCELLED', PostgreSQL sẽ tự động đánh thức:
    -- + trigger_order_cancel_restore_stock: Tìm lại lịch sử trừ Lô (Batch) và cộng trả kho nguyên vẹn.
    -- + trg_update_debt_from_orders: Trừ lại phần nợ đã ghi nhận cho khách.
    UPDATE public.orders
    SET status = 'CANCELLED',
        note = COALESCE(note, '') || E'\n--- \n[HỦY ĐƠN ' || TO_CHAR(NOW(), 'DD/MM/YYYY HH24:MI') || '] - Người hủy: ' || v_user_name || ' - Lý do: ' || p_reason,
        updated_at = NOW()
    WHERE id = p_order_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã hủy đơn hàng thành công! Hệ thống đã tự động hoàn trả kho và công nợ (nếu có).'
    );
END;
$function$
