CREATE OR REPLACE FUNCTION public.confirm_transaction(p_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_current_status public.transaction_status;
BEGIN
    -- 1. Kiểm tra trạng thái hiện tại
    SELECT status INTO v_current_status FROM public.finance_transactions WHERE id = p_id;
    
    IF v_current_status = 'confirmed' THEN
        RAISE EXCEPTION 'Giao dịch này đã được duyệt trước đó.';
    END IF;

    IF v_current_status = 'cancelled' THEN
        RAISE EXCEPTION 'Không thể duyệt giao dịch đã bị hủy.';
    END IF;

    -- 2. Cập nhật trạng thái -> Trigger sẽ tự động trừ/cộng tiền
    UPDATE public.finance_transactions 
    SET status = 'confirmed', updated_at = now()
    WHERE id = p_id;

    RETURN TRUE;
END;
$function$
