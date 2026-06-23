CREATE OR REPLACE FUNCTION public.import_opening_stock_v3_by_id(p_warehouse_id bigint, p_user_id uuid, p_stock_array jsonb[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_item JSONB;
        v_product_id BIGINT;
        v_qty_input NUMERIC;
        v_qty_final NUMERIC;
        v_unit_price_input NUMERIC;
        v_unit_price_base NUMERIC;
        v_lot_code TEXT;
        v_exp_date DATE;
        v_batch_id BIGINT;
        v_conversion_rate INTEGER;
        v_total_items INTEGER := 0;
        v_receipt_code TEXT;
        v_receipt_id BIGINT;
    BEGIN
        -- 1. Validate
        IF p_warehouse_id IS NULL THEN
            RAISE EXCEPTION 'Chưa chọn kho nhập liệu.';
        END IF;

        -- 2. Tạo Header (Phiếu Nhập Tồn)
        v_receipt_code := 'OPENING-' || TO_CHAR(NOW(), 'YYMMDD-HH24MI') || '-' || FLOOR(RANDOM() * 1000)::TEXT;
        
        -- Lưu ý: Trigger calculate_receipt_totals sẽ tự động tính final_amount sau khi insert items
        INSERT INTO public.inventory_receipts (
            code, warehouse_id, receipt_date, status, creator_id, created_at, note
        ) VALUES (
            v_receipt_code, p_warehouse_id, NOW(), 'completed', p_user_id, NOW(), 'Nhập tồn đầu kỳ'
        ) RETURNING id INTO v_receipt_id;

        -- 3. Loop Items
        FOREACH v_item IN ARRAY p_stock_array
        LOOP
            v_product_id := (v_item->>'product_id')::BIGINT;
            v_qty_input  := COALESCE((v_item->>'quantity')::NUMERIC, 0);
            v_unit_price_input := COALESCE((v_item->>'cost_price')::NUMERIC, 0); -- Giá vốn đầu vào
            v_lot_code   := NULLIF(TRIM(v_item->>'batch_name'), '');
            
            -- A. Quy đổi đơn vị (Số lượng & Giá)
            IF (v_item->>'is_large_unit')::BOOLEAN = true THEN
                SELECT conversion_rate INTO v_conversion_rate
                FROM public.product_units
                WHERE product_id = v_product_id AND conversion_rate > 1
                ORDER BY conversion_rate DESC LIMIT 1;
                v_conversion_rate := COALESCE(v_conversion_rate, 1);
            ELSE
                v_conversion_rate := 1;
            END IF;

            v_qty_final := v_qty_input * v_conversion_rate;
            
            -- Tính giá vốn cơ sở (Base Cost) = Giá nhập / Hệ số
            IF v_conversion_rate > 0 THEN
                v_unit_price_base := v_unit_price_input / v_conversion_rate;
            ELSE
                v_unit_price_base := v_unit_price_input;
            END IF;

            -- B. Xử lý Date
            BEGIN
                IF (v_item->>'expiry_date') IS NOT NULL AND (v_item->>'expiry_date') <> '' THEN
                     v_exp_date := (v_item->>'expiry_date')::DATE;
                ELSE
                     v_exp_date := NULL;
                END IF;
            EXCEPTION WHEN OTHERS THEN
                v_exp_date := NULL;
            END;

            IF v_qty_final > 0 THEN
                
                -- C. Xử lý Batch (Tìm hoặc Tạo & Cập nhật giá vốn lô)
                IF v_lot_code IS NULL THEN v_lot_code := 'DEFAULT-OPENING'; END IF;

                SELECT id INTO v_batch_id 
                FROM public.batches 
                WHERE product_id = v_product_id AND batch_code = v_lot_code;

                IF v_batch_id IS NULL THEN
                    INSERT INTO public.batches (product_id, batch_code, expiry_date, inbound_price, created_at) 
                    VALUES (v_product_id, v_lot_code, COALESCE(v_exp_date, '2099-12-31'::DATE), v_unit_price_base, NOW()) 
                    RETURNING id INTO v_batch_id;
                ELSE
                    -- Nếu lô đã có, cập nhật lại giá vốn
                    UPDATE public.batches SET inbound_price = v_unit_price_base WHERE id = v_batch_id;
                END IF;

                -- D. Cập nhật Tồn kho chi tiết (Inventory Batches)
                INSERT INTO public.inventory_batches (
                    warehouse_id, product_id, batch_id, quantity, updated_at
                ) VALUES (
                    p_warehouse_id, v_product_id, v_batch_id, v_qty_final, NOW()
                )
                ON CONFLICT (warehouse_id, product_id, batch_id) 
                DO UPDATE SET 
                    quantity = public.inventory_batches.quantity + EXCLUDED.quantity,
                    updated_at = NOW();

                -- E. Ghi Sổ Cái (Inventory Transactions - Tài chính kho)
                INSERT INTO public.inventory_transactions (
                    warehouse_id, product_id, batch_id, type, action_group, quantity, unit_price, ref_id, description, created_at, created_by
                ) VALUES (
                    p_warehouse_id, v_product_id, v_batch_id, 'opening_stock', 'IMPORT', v_qty_final, v_unit_price_base, v_receipt_code, 'Nhập tồn đầu kỳ', NOW(), p_user_id
                );

                -- F. [QUAN TRỌNG NHẤT] Ghi chi tiết phiếu nhập kèm GIÁ (Phục vụ đối chiếu công nợ/tồn kho)
                INSERT INTO public.inventory_receipt_items (
                    receipt_id, product_id, quantity, lot_number, expiry_date, 
                    unit_price, discount_amount
                ) VALUES (
                    v_receipt_id, v_product_id, v_qty_final, v_lot_code, v_exp_date,
                    v_unit_price_base, 0 
                );
                
                -- G. Cập nhật giá vốn tham khảo cho sản phẩm (Nếu chưa có)
                IF v_unit_price_base > 0 THEN
                    UPDATE public.products SET actual_cost = v_unit_price_base, updated_at = NOW()
                    WHERE id = v_product_id AND (actual_cost IS NULL OR actual_cost = 0);
                END IF;

                v_total_items := v_total_items + 1;
            END IF;
        END LOOP;

        RETURN jsonb_build_object('success', true, 'imported_count', v_total_items, 'receipt_code', v_receipt_code);
    END;
    $function$
