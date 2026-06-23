CREATE OR REPLACE FUNCTION public.cancel_outbound_task(p_order_id uuid, p_reason text, p_user_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_user_email TEXT;
        v_current_status TEXT;
    BEGIN
        SELECT status INTO v_current_status FROM public.orders WHERE id = p_order_id;
        
        IF v_current_status = 'DELIVERED' THEN
            RAISE EXCEPTION 'Không thể hủy đơn đã giao thành công.';
        END IF;

        SELECT email INTO v_user_email FROM auth.users WHERE id = p_user_id;

        UPDATE public.orders
        SET 
            status = 'CANCELLED',
            note = COALESCE(note, '') || E'\n[Hủy kho bởi ' || COALESCE(v_user_email, 'User') || ': ' || p_reason || ']',
            updated_at = NOW()
        WHERE id = p_order_id;

        RETURN jsonb_build_object('success', true, 'message', 'Đã hủy nhiệm vụ xuất kho.');
    END;
    $function$
