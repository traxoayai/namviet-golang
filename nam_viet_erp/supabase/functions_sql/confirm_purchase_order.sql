CREATE OR REPLACE FUNCTION public.confirm_purchase_order(p_po_id bigint, p_status text)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item_count INT;
BEGIN
    -- 1. Validate: Không được duyệt đơn rỗng
    SELECT COUNT(*) INTO v_item_count
    FROM public.purchase_order_items
    WHERE po_id = p_po_id;

    IF v_item_count = 0 THEN
        RAISE EXCEPTION 'Đơn hàng rỗng, không thể duyệt. Vui lòng thêm sản phẩm.';
    END IF;

    -- 2. Cập nhật trạng thái
    UPDATE public.purchase_orders
    SET 
        status = p_status,
        -- Tự động chuyển sang 'pending' (chờ giao) nếu user duyệt 'APPROVED'
        delivery_status = CASE WHEN p_status = 'APPROVED' THEN 'pending' ELSE delivery_status END,
        updated_at = NOW()
    WHERE id = p_po_id;
    
    RETURN TRUE;
END;
$function$
