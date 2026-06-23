CREATE OR REPLACE FUNCTION public.create_inventory_receipt(p_po_id bigint, p_warehouse_id bigint, p_note text, p_items jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_receipt_id BIGINT;
        v_item JSONB;
        v_code TEXT;
    BEGIN
        -- A. Tạo Mã Phiếu Nhập (PNK-YYMMDD-XXXX)
        v_code := public._gen_finance_tx_code('PNK');

        -- B. Insert Header Phiếu Nhập
        INSERT INTO public.inventory_receipts (
            code, po_id, warehouse_id, creator_id, receipt_date, note, status
        )
        VALUES (
            v_code, p_po_id, p_warehouse_id, auth.uid(), now(), p_note, 'completed'
        )
        RETURNING id INTO v_receipt_id;

        -- C. Insert Chi Tiết & Cập nhật Tồn Kho
        FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
        LOOP
            -- 1. Lưu dòng chi tiết nhập
            INSERT INTO public.inventory_receipt_items (
                receipt_id, product_id, quantity, lot_number, expiry_date
            )
            VALUES (
                v_receipt_id,
                (v_item->>'product_id')::BIGINT,
                (v_item->>'quantity')::INTEGER,
                v_item->>'lot_number',
                (v_item->>'expiry_date')::DATE
            );

            -- 2. Cộng Tồn Kho (Vào bảng product_inventory)
            UPDATE public.product_inventory
            SET stock_quantity = stock_quantity + (v_item->>'quantity')::INTEGER
            WHERE product_id = (v_item->>'product_id')::BIGINT 
              AND warehouse_id = p_warehouse_id;
            
            -- Nếu chưa có dòng tồn kho thì insert (phòng hờ)
            IF NOT FOUND THEN
                INSERT INTO public.product_inventory (product_id, warehouse_id, stock_quantity, min_stock, max_stock)
                VALUES ((v_item->>'product_id')::BIGINT, p_warehouse_id, (v_item->>'quantity')::INTEGER, 0, 100);
            END IF;

            -- 3. Cập nhật số lượng đã nhập vào PO Items (Quan trọng để tính công nợ/đối chiếu)
            UPDATE public.purchase_order_items
            SET quantity_received = COALESCE(quantity_received, 0) + (v_item->>'quantity')::INTEGER
            WHERE po_id = p_po_id 
              AND product_id = (v_item->>'product_id')::BIGINT;
        END LOOP;

        -- D. Cập nhật trạng thái PO thành ĐÃ NHẬP (Theo yêu cầu AURA)
        UPDATE public.purchase_orders
        SET 
            delivery_status = 'delivered', -- Đã giao hàng
            status = 'COMPLETED',          -- Quy trình hoàn tất
            updated_at = now()
        WHERE id = p_po_id;

        RETURN v_receipt_id;
    END;
    $function$
