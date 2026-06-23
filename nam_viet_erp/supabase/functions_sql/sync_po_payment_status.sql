CREATE OR REPLACE FUNCTION public.sync_po_payment_status()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$DECLARE
    v_po_id BIGINT;
    v_total_paid NUMERIC;
    v_final_amount NUMERIC;
    v_new_status TEXT;
BEGIN
    -- 1. Xác định ID Đơn Mua Hàng bị ảnh hưởng
    -- Nếu là DELETE, lấy ID từ bản ghi cũ (OLD). Nếu INSERT/UPDATE, lấy từ bản ghi mới (NEW).
    IF (TG_OP = 'DELETE') THEN
        IF OLD.ref_type = 'purchase_order' AND OLD.ref_id IS NOT NULL THEN
            v_po_id := OLD.ref_id::BIGINT;
        ELSE
            RETURN NULL; -- Không liên quan đến PO
        END IF;
    ELSE
        IF NEW.ref_type = 'purchase_order' AND NEW.ref_id IS NOT NULL THEN
            v_po_id := NEW.ref_id::BIGINT;
        ELSE
            RETURN NULL; -- Không liên quan đến PO
        END IF;
    END IF;

    -- 2. Tính tổng tiền thực tế ĐÃ ĐƯỢC CHẤP NHẬN CHI cho đơn này
    -- Chỉ cộng các phiếu có status là 'completed' hoặc 'confirmed'
    SELECT COALESCE(SUM(amount), 0)
    INTO v_total_paid
    FROM public.finance_transactions
    WHERE ref_type = 'purchase_order' 
      AND ref_id = v_po_id::TEXT
      AND flow = 'out' -- Chỉ tính dòng tiền ra (Chi)
      AND status IN ('confirmed', 'completed', 'approved'); -- Chỉ tính phiếu đã duyệt

    -- 3. Lấy tổng tiền phải trả của đơn hàng
    SELECT final_amount INTO v_final_amount 
    FROM public.purchase_orders 
    WHERE id = v_po_id;

    -- Nếu không tìm thấy đơn (trường hợp hiếm), thoát luôn
    IF v_final_amount IS NULL THEN RETURN NULL; END IF;

    -- 4. Xác định trạng thái mới dựa trên số liệu thực tế
    IF v_total_paid >= (v_final_amount - 500) THEN -- Cho phép sai số 500đ
        v_new_status := 'paid';
    ELSIF v_total_paid > 0 THEN
        v_new_status := 'partial';
    ELSE
        v_new_status := 'unpaid';
    END IF;

    -- 5. Cập nhật ngược lại bảng PO
    UPDATE public.purchase_orders
    SET total_paid = v_total_paid,
        payment_status = v_new_status,
        updated_at = NOW()
    WHERE id = v_po_id;

    RETURN NULL; -- Trigger AFTER không cần trả về giá trị
END;$function$
