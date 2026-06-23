CREATE OR REPLACE FUNCTION public.save_inbound_draft(p_po_id bigint, p_draft_data jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    UPDATE public.purchase_orders
    SET receipt_draft = p_draft_data,
        updated_at = NOW()
    WHERE id = p_po_id;

    RETURN jsonb_build_object(
        'success', true,
        'message', 'Đã lưu nháp tiến độ kiểm hàng.'
    );
END;
$function$
