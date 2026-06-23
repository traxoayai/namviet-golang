CREATE OR REPLACE FUNCTION public.execute_vaccination_combo(p_appointment_id uuid, p_customer_id bigint, p_scanned_product_ids bigint[], p_warehouse_id bigint, p_nurse_id uuid DEFAULT auth.uid())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_prod_id BIGINT;
    v_batch RECORD;
    v_qty_needed INT;
    v_order_code TEXT;
BEGIN
    -- 1. Lấy mã phiếu để làm Ref ID cho Kế toán
    SELECT code INTO v_order_code FROM public.orders 
    WHERE id = (SELECT order_id FROM public.customer_vaccination_records WHERE appointment_id = p_appointment_id LIMIT 1);
    IF v_order_code IS NULL THEN v_order_code := 'VACCINE-' || p_appointment_id::text; END IF;

    -- 2. Cập nhật Sổ Tiêm Chủng
    UPDATE public.customer_vaccination_records
    SET 
        status = 'completed',
        actual_date = CURRENT_DATE,
        administered_by = p_nurse_id,
        updated_at = NOW()
    WHERE appointment_id = p_appointment_id 
      AND product_id = ANY(p_scanned_product_ids)
      AND status = 'pending';

    -- 3. VÒNG LẶP TRỪ KHO FEFO CHO TỪNG LỌ VẮC-XIN
    FOREACH v_prod_id IN ARRAY p_scanned_product_ids
    LOOP
        v_qty_needed := 1; -- Mỗi mũi tiêm mặc định là 1 Base Unit (1 Lọ/Ống)

        -- Quét tìm Lô (Batch) cận date nhất trong tủ lạnh
        FOR v_batch IN 
            SELECT ib.id, ib.batch_id, ib.quantity, b.batch_code, b.inbound_price
            FROM public.inventory_batches ib
            JOIN public.batches b ON ib.batch_id = b.id
            WHERE ib.warehouse_id = p_warehouse_id
              AND ib.product_id = v_prod_id
              AND ib.quantity > 0
            ORDER BY b.expiry_date ASC, b.created_at ASC
            FOR UPDATE -- Khóa dòng chống double-spending
        LOOP
            IF v_qty_needed <= 0 THEN EXIT; END IF;

            -- Trừ kho Lô
            UPDATE public.inventory_batches
            SET quantity = quantity - 1, updated_at = NOW()
            WHERE id = v_batch.id;

            -- Ghi Log Phiếu Xuất (Inventory Transaction) cho Kế toán
            INSERT INTO public.inventory_transactions (
                warehouse_id, product_id, batch_id, type, action_group, 
                quantity, unit_price, ref_id, description, partner_id, created_by
            ) VALUES (
                p_warehouse_id, v_prod_id, v_batch.batch_id, 'sale_order', 'USE', 
                -1, -- Xuất kho ghi âm
                COALESCE(v_batch.inbound_price, 0), v_order_code, 
                'Xuất sử dụng Vắc-xin (Lô: ' || v_batch.batch_code || ')', 
                p_customer_id, p_nurse_id
            );

            v_qty_needed := 0;
        END LOOP;

        -- [CẢNH BÁO MẠNH MẼ]: Nếu thuốc không có trong kho vẫn bị trừ âm?
        -- Tạm thời theo logic ERP: Báo lỗi để Y tá phải làm phiếu nhập kho trước.
        IF v_qty_needed > 0 THEN
            RAISE EXCEPTION 'Trong tủ lạnh (Kho ID: %) không còn thuốc cho Product ID: %', p_warehouse_id, v_prod_id;
        END IF;

        -- Trừ kho Tổng (Bảng product_inventory)
        UPDATE public.product_inventory
        SET stock_quantity = stock_quantity - 1, updated_at = NOW()
        WHERE warehouse_id = p_warehouse_id AND product_id = v_prod_id;

    END LOOP;

    -- 4. Chuyển trạng thái Bệnh nhân sang Đợi 30 phút Sốc phản vệ
    UPDATE public.appointments SET status = 'observing', updated_at = NOW() WHERE id = p_appointment_id;
    UPDATE public.clinical_queues SET status = 'observing', updated_at = NOW() WHERE appointment_id = p_appointment_id;

    RETURN jsonb_build_object('success', true, 'message', 'Đã xác nhận tiêm, trừ kho thành công. Chuyển bệnh nhân sang khu vực theo dõi 30 phút.');
END;
$function$
