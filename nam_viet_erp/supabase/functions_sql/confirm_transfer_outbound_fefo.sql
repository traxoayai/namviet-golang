CREATE OR REPLACE FUNCTION public.confirm_transfer_outbound_fefo(p_transfer_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_transfer_record RECORD;
    v_item RECORD;
    v_batch_record RECORD;
    v_qty_needed_base INTEGER; -- Số lượng cần xuất (Base Unit)
    v_qty_take INTEGER;        -- Số lượng lấy từ 1 lô
BEGIN
    -- 1. Lấy thông tin phiếu & Lock dòng để tránh tranh chấp
    SELECT * INTO v_transfer_record 
    FROM public.inventory_transfers 
    WHERE id = p_transfer_id 
    FOR UPDATE;

    IF v_transfer_record IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy phiếu chuyển kho ID %', p_transfer_id;
    END IF;

    IF v_transfer_record.status NOT IN ('pending', 'approved') THEN
        RAISE EXCEPTION 'Phiếu không ở trạng thái có thể xuất kho (Status: %)', v_transfer_record.status;
    END IF;

    -- 2. Duyệt qua từng sản phẩm trong phiếu
    FOR v_item IN 
        SELECT * FROM public.inventory_transfer_items 
        WHERE transfer_id = p_transfer_id
    LOOP
        -- Tính tổng số lượng Base Unit cần xuất
        -- Công thức: (Qty Requested * Conversion Factor) - (Đã xuất nếu có)
        v_qty_needed_base := (v_item.qty_requested * COALESCE(v_item.conversion_factor, 1))::INTEGER - COALESCE(v_item.qty_shipped, 0)::INTEGER;

        -- Nếu dòng này đã xuất đủ hoặc không cần xuất -> Bỏ qua
        IF v_qty_needed_base <= 0 THEN CONTINUE; END IF;

        -- 3. [CORE FIX]: Tìm các lô trong Kho Nguồn theo FEFO (Phải JOIN bảng batches)
        FOR v_batch_record IN 
            SELECT ib.id, ib.batch_id, ib.quantity 
            FROM public.inventory_batches ib
            JOIN public.batches b ON ib.batch_id = b.id -- Join để lấy expiry_date
            WHERE ib.warehouse_id = v_transfer_record.source_warehouse_id
              AND ib.product_id = v_item.product_id
              AND ib.quantity > 0
            ORDER BY b.expiry_date ASC, b.created_at ASC -- Ưu tiên hết hạn trước, nhập trước
        LOOP
            -- Tính số lượng lấy từ lô này
            IF v_batch_record.quantity >= v_qty_needed_base THEN
                v_qty_take := v_qty_needed_base;
            ELSE
                v_qty_take := v_batch_record.quantity;
            END IF;

            -- A. Trừ kho lô này (Inventory Batches)
            UPDATE public.inventory_batches
            SET quantity = quantity - v_qty_take,
                updated_at = NOW()
            WHERE id = v_batch_record.id;

            -- B. Ghi log tracking (Để biết phiếu này đã lấy hàng từ lô nào)
            INSERT INTO public.inventory_transfer_batch_items (
                transfer_item_id, batch_id, quantity
            ) VALUES (
                v_item.id, v_batch_record.batch_id, v_qty_take
            );
            
            -- C. [QUAN TRỌNG] Ghi Inventory Transactions (Sổ cái kho)
            INSERT INTO public.inventory_transactions (
                warehouse_id, product_id, batch_id, type, action_group, 
                quantity, unit_price, ref_id, description, created_by
            ) VALUES (
                v_transfer_record.source_warehouse_id,
                v_item.product_id,
                v_batch_record.batch_id,
                'transfer_out', -- Loại giao dịch
                'TRANSFER',
                -v_qty_take,    -- Số lượng âm (xuất)
                0,              -- Giá vốn (Có thể update sau hoặc lấy từ product)
                v_transfer_record.code,
                'Xuất chuyển kho tới ' || v_transfer_record.dest_warehouse_id,
                auth.uid()
            );

            -- D. Giảm số lượng cần tìm
            v_qty_needed_base := v_qty_needed_base - v_qty_take;

            -- Nếu đã đủ hàng -> Dừng tìm lô tiếp
            IF v_qty_needed_base = 0 THEN EXIT; END IF;
        END LOOP;

        -- 4. Nếu sau khi quét hết kho mà vẫn thiếu hàng -> Báo lỗi chặn lại
        IF v_qty_needed_base > 0 THEN
            RAISE EXCEPTION 'Kho nguồn không đủ hàng cho sản phẩm ID %. Thiếu % (Base Unit). Vui lòng kiểm tra tồn kho.', v_item.product_id, v_qty_needed_base;
        END IF;

        -- 5. Cập nhật số lượng đã xuất vào Item
        UPDATE public.inventory_transfer_items
        SET qty_shipped = (v_item.qty_requested * COALESCE(v_item.conversion_factor, 1)) -- Lưu theo Base
        WHERE id = v_item.id;

    END LOOP;

    -- 6. Cập nhật trạng thái phiếu -> SHIPPING
    UPDATE public.inventory_transfers
    SET status = 'shipping',
        updated_at = NOW()
    WHERE id = p_transfer_id;

    RETURN jsonb_build_object('success', true, 'message', 'Đã xuất kho thành công (Auto-FEFO).');
END;
$function$
