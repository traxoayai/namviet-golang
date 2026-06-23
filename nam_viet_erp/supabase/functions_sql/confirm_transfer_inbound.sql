CREATE OR REPLACE FUNCTION public.confirm_transfer_inbound(p_transfer_id bigint, p_actor_warehouse_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public'
AS $function$
DECLARE
    v_transfer_record RECORD;
    v_batch_track RECORD;
    v_received_count INT := 0;
    v_source_wh_name TEXT; 
BEGIN
    -- 1. Validate & Lock phiếu (Chống Race Condition)
    SELECT * INTO v_transfer_record 
    FROM public.inventory_transfers 
    WHERE id = p_transfer_id 
    FOR UPDATE;

    IF v_transfer_record IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy phiếu chuyển kho ID %', p_transfer_id;
    END IF;

    IF v_transfer_record.status != 'shipping' THEN
        RAISE EXCEPTION 'Phiếu không ở trạng thái chờ nhập kho (Status: %).', v_transfer_record.status;
    END IF;

    -- Validate đúng kho đích mới được nhập
    IF v_transfer_record.dest_warehouse_id != p_actor_warehouse_id THEN
        RAISE EXCEPTION 'Mã kho thực hiện (%) không trùng khớp với kho đích (%).', p_actor_warehouse_id, v_transfer_record.dest_warehouse_id;
    END IF;

    -- Lấy tên kho nguồn để ghi log
    SELECT name INTO v_source_wh_name 
    FROM public.warehouses 
    WHERE id = v_transfer_record.source_warehouse_id;

    -- 2. DUYỆT CÁC LÔ ĐÃ XUẤT ĐỂ CỘNG VÀO KHO ĐÍCH
    FOR v_batch_track IN 
        SELECT 
            itbi.batch_id,
            itbi.quantity, 
            iti.product_id
        FROM public.inventory_transfer_batch_items itbi
        JOIN public.inventory_transfer_items iti ON itbi.transfer_item_id = iti.id
        WHERE iti.transfer_id = p_transfer_id
    LOOP
        -- A. Cập nhật Lô hàng chi tiết (Trigger hệ thống không quản lý lô, nên ta phải cộng tay ở đây)
        INSERT INTO public.inventory_batches (
            warehouse_id, product_id, batch_id, quantity, updated_at
        ) VALUES (
            v_transfer_record.dest_warehouse_id, v_batch_track.product_id, v_batch_track.batch_id, v_batch_track.quantity, NOW()
        )
        ON CONFLICT (warehouse_id, product_id, batch_id) 
        DO UPDATE SET 
            quantity = public.inventory_batches.quantity + EXCLUDED.quantity,
            updated_at = NOW();

        -- B. [CORE & SENKO FIX]: Khởi tạo dòng tồn kho tổng (Zero-Initialization)
        -- Tuyệt đối KHÔNG cộng dồn số lượng ở đây. Tránh lỗi Double-Dip.
        INSERT INTO public.product_inventory (
            warehouse_id, product_id, stock_quantity, updated_at
        ) VALUES (
            v_transfer_record.dest_warehouse_id, v_batch_track.product_id, 0, NOW()
        )
        ON CONFLICT (warehouse_id, product_id) DO NOTHING;

        -- C. Ghi Log Giao dịch (Trigger ngầm sẽ bắt sự kiện này và TỰ ĐỘNG CỘNG tồn kho tổng)
        INSERT INTO public.inventory_transactions (
            warehouse_id, product_id, batch_id, 
            type, action_group, quantity, unit_price, 
            ref_id, description, created_by, created_at
        ) VALUES (
            v_transfer_record.dest_warehouse_id,
            v_batch_track.product_id,
            v_batch_track.batch_id,
            'transfer_in', 
            'TRANSFER',
            v_batch_track.quantity, 
            0,
            v_transfer_record.code,
            'Nhập kho chuyển từ ' || COALESCE(v_source_wh_name, 'Kho #' || v_transfer_record.source_warehouse_id),
            auth.uid(),
            NOW()
        );

        v_received_count := v_received_count + 1;
    END LOOP;

    -- 3. Cập nhật trạng thái phiếu -> COMPLETED
    UPDATE public.inventory_transfers
    SET status = 'completed',
        received_by = auth.uid(),
        received_at = NOW(),
        updated_at = NOW()
    WHERE id = p_transfer_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã nhập kho thành công.',
        'items_processed', v_received_count
    );
END;
$function$
