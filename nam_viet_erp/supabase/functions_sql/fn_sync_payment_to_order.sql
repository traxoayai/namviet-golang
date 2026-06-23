CREATE OR REPLACE FUNCTION public.fn_sync_payment_to_order()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_order_id UUID;
    v_total_paid NUMERIC;
    v_final_amount NUMERIC;
    v_ref_id TEXT;
BEGIN
    -- Lấy ref_id từ bản ghi mới (hoặc cũ nếu đang bị xóa/sửa)
    v_ref_id := COALESCE(NEW.ref_id, OLD.ref_id);

    -- Bước 1: Tìm ID thực sự của Đơn hàng (Dò cả Code và UUID)
    SELECT id, final_amount INTO v_order_id, v_final_amount
    FROM public.orders 
    WHERE id::text = v_ref_id OR code = v_ref_id
    LIMIT 1;

    -- Bước 2: Tiến hành tính lại TỔNG TIỀN ĐÃ TRẢ nếu tìm thấy đơn
    IF v_order_id IS NOT NULL THEN
        -- Tính tổng MỌI phiếu thu (in) đang có trạng thái (completed) của đơn này
        SELECT COALESCE(SUM(amount), 0) INTO v_total_paid
        FROM public.finance_transactions
        WHERE flow = 'in' AND status = 'completed' AND ref_type = 'order'
          AND (ref_id = v_order_id::text OR ref_id = (SELECT code FROM public.orders WHERE id = v_order_id));

        -- Bước 3: Cập nhật ngược lại bảng Orders một cách chính xác tuyệt đối
        UPDATE public.orders
        SET 
            paid_amount = v_total_paid,
            payment_status = CASE 
                WHEN v_total_paid >= v_final_amount THEN 'paid'
                WHEN v_total_paid > 0 THEN 'partial'
                ELSE 'unpaid'
            END,
            updated_at = NOW()
        WHERE id = v_order_id;
    END IF;
    
    RETURN COALESCE(NEW, OLD);
END;
$function$
