CREATE OR REPLACE FUNCTION public.submit_transfer_shipping(p_transfer_id bigint, p_batch_items jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_transfer_record RECORD;
        v_item JSONB;
        v_item_record RECORD;
        
        v_qty_wholesale NUMERIC;
        v_qty_base INTEGER;
        
        v_batch_id BIGINT;
        v_transfer_item_id BIGINT;
        v_source_warehouse_id BIGINT;
        v_current_stock INTEGER;
    BEGIN
        -- 1. Validate Header & Lock Row
        SELECT * INTO v_transfer_record 
        FROM public.inventory_transfers 
        WHERE id = p_transfer_id 
        FOR UPDATE; -- Khóa dòng phiếu chuyển

        IF v_transfer_record IS NULL THEN
            RAISE EXCEPTION 'Không tìm thấy phiếu chuyển kho ID %', p_transfer_id;
        END IF;

        IF v_transfer_record.status NOT IN ('pending', 'approved') THEN
            RAISE EXCEPTION 'Phiếu chuyển kho không ở trạng thái chờ xuất (Status hiện tại: %)', v_transfer_record.status;
        END IF;

        v_source_warehouse_id := v_transfer_record.source_warehouse_id;

        -- 2. Loop xử lý từng dòng Batch
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_batch_items)
        LOOP
            v_transfer_item_id := (v_item->>'transfer_item_id')::BIGINT;
            v_batch_id := (v_item->>'batch_id')::BIGINT;
            v_qty_wholesale := (v_item->>'quantity')::NUMERIC; -- Số lượng Sỉ (VD: 5 Thùng)

            IF v_qty_wholesale <= 0 THEN
                CONTINUE; -- Bỏ qua nếu số lượng = 0
            END IF;

            -- Lấy thông tin Item để biết hệ số quy đổi
            SELECT * INTO v_item_record
            FROM public.inventory_transfer_items
            WHERE id = v_transfer_item_id;

            IF v_item_record IS NULL THEN
                RAISE EXCEPTION 'Không tìm thấy dòng chi tiết ID %', v_transfer_item_id;
            END IF;

            -- A. Tính toán quy đổi ra Base Unit
            v_qty_base := (v_qty_wholesale * v_item_record.conversion_factor)::INTEGER;

            -- B. Trừ kho (Inventory Batches) tại Kho Nguồn
            UPDATE public.inventory_batches
            SET quantity = quantity - v_qty_base,
                updated_at = NOW()
            WHERE warehouse_id = v_source_warehouse_id
              AND batch_id = v_batch_id
              AND product_id = v_item_record.product_id
            RETURNING quantity INTO v_current_stock;

            -- Kiểm tra nếu không tìm thấy lô hoặc âm kho
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Lô hàng ID % không tồn tại trong kho nguồn (Product ID %)', v_batch_id, v_item_record.product_id;
            END IF;

            IF v_current_stock < 0 THEN
                RAISE EXCEPTION 'Kho không đủ hàng để xuất. Sản phẩm ID %, Lô ID % bị âm.', v_item_record.product_id, v_batch_id;
            END IF;

            -- C. Ghi nhận Batch vào bảng Tracking (inventory_transfer_batch_items)
            -- Bảng này lưu số lượng thực tế (Base Unit) đã lấy từ lô nào
            INSERT INTO public.inventory_transfer_batch_items (
                transfer_item_id, batch_id, quantity
            ) VALUES (
                v_transfer_item_id, v_batch_id, v_qty_base
            );

            -- D. Cập nhật tiến độ vào bảng Item (Số lượng Sỉ)
            UPDATE public.inventory_transfer_items
            SET qty_shipped = COALESCE(qty_shipped, 0) + v_qty_wholesale
            WHERE id = v_transfer_item_id;

        END LOOP;

        -- 3. Cập nhật trạng thái Header -> SHIPPING
        UPDATE public.inventory_transfers
        SET status = 'shipping',
            updated_at = NOW()
        WHERE id = p_transfer_id;

        RETURN jsonb_build_object(
            'success', true, 
            'message', 'Đã xác nhận xuất kho. Phiếu chuyển sang trạng thái Đang vận chuyển.'
        );
    END;
    $function$
