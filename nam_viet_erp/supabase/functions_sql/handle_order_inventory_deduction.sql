CREATE OR REPLACE FUNCTION public.handle_order_inventory_deduction()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_item RECORD;
        v_warehouse_id BIGINT;
        v_deduct_qty NUMERIC;
        v_batch_record RECORD;
        v_remaining_qty_needed NUMERIC;
        v_deduct_amount NUMERIC;
        v_unit_cost NUMERIC; 
        v_partner_id BIGINT; 
        v_agg_batch_no TEXT;
        v_min_expiry DATE;
    BEGIN
        -- [FIX 2026-04-09]: Không trừ kho khi status = CONFIRMED (trừ khi là POS)
        -- Điều kiện: Nếu status mới là các trạng thái xuất kho thực tế (PACKED/SHIPPING/DELIVERED)
        -- HOẶC là POS chốt đơn ngay.
        -- ĐỒNG THỜI trạng thái cũ không nằm trong nhóm đã xuất kho.
        
        IF (
            (NEW.status IN ('DELIVERED', 'POS_COMPLETED', 'PACKED', 'SHIPPING'))
            OR (NEW.order_type = 'POS' AND NEW.status = 'CONFIRMED')
           )
           AND (OLD.status IS NULL OR OLD.status NOT IN ('DELIVERED', 'POS_COMPLETED', 'PACKED', 'SHIPPING')) 
        THEN

            v_warehouse_id := NEW.warehouse_id;
            IF v_warehouse_id IS NULL THEN v_warehouse_id := 1; END IF;
            
            v_partner_id := NEW.customer_id; 

            FOR v_item IN SELECT * FROM public.order_items WHERE order_id = NEW.id
            LOOP
                -- Nếu dòng đã được gán lô (đã trừ từ bước khác/RPC khác) thì bỏ qua
                IF v_item.batch_no IS NOT NULL AND v_item.batch_no <> '' THEN
                    CONTINUE;
                END IF;

                v_deduct_qty := v_item.quantity * COALESCE(v_item.conversion_factor, 1);

                SELECT COALESCE(actual_cost, 0) INTO v_unit_cost
                FROM public.products
                WHERE id = v_item.product_id;

                v_remaining_qty_needed := v_deduct_qty;
                v_agg_batch_no := '';
                v_min_expiry := NULL;

                FOR v_batch_record IN 
                    SELECT b.id, b.quantity, batch_info.batch_code, batch_info.expiry_date, batch_info.id as batch_id, batch_info.inbound_price
                    FROM public.inventory_batches b
                    JOIN public.batches batch_info ON b.batch_id = batch_info.id
                    WHERE b.warehouse_id = v_warehouse_id
                      AND b.product_id = v_item.product_id
                      AND b.quantity > 0
                    ORDER BY batch_info.expiry_date ASC NULLS LAST, batch_info.created_at ASC
                    FOR UPDATE
                LOOP
                    IF v_remaining_qty_needed <= 0 THEN EXIT; END IF;

                    IF v_batch_record.quantity >= v_remaining_qty_needed THEN
                        v_deduct_amount := v_remaining_qty_needed;
                        UPDATE public.inventory_batches SET quantity = quantity - v_remaining_qty_needed, updated_at = NOW() WHERE id = v_batch_record.id;
                        v_remaining_qty_needed := 0;
                    ELSE
                        v_deduct_amount := v_batch_record.quantity;
                        UPDATE public.inventory_batches SET quantity = 0, updated_at = NOW() WHERE id = v_batch_record.id;
                        v_remaining_qty_needed := v_remaining_qty_needed - v_batch_record.quantity;
                    END IF;

                    INSERT INTO public.inventory_transactions (
                        warehouse_id, product_id, quantity, type, ref_id, description, 
                        created_at, action_group, unit_price, partner_id, batch_id
                    ) VALUES (
                        v_warehouse_id, v_item.product_id, -v_deduct_amount, 'sale_order', 
                        NEW.code, 'Xuất bán đơn hàng ' || NEW.code, NOW(), 'SALE', 
                        COALESCE(v_batch_record.inbound_price, v_unit_cost), v_partner_id, v_batch_record.batch_id
                    );

                    IF v_agg_batch_no = '' THEN 
                        v_agg_batch_no := v_batch_record.batch_code; 
                        v_min_expiry := v_batch_record.expiry_date;
                    ELSE 
                        v_agg_batch_no := v_agg_batch_no || ', ' || v_batch_record.batch_code;
                    END IF;
                END LOOP;

                UPDATE public.order_items 
                SET batch_no = v_agg_batch_no, expiry_date = v_min_expiry, quantity_picked = (v_item.quantity * COALESCE(v_item.conversion_factor, 1))
                WHERE id = v_item.id;

                UPDATE public.product_inventory
                SET stock_quantity = stock_quantity - v_deduct_qty, updated_at = NOW()
                WHERE warehouse_id = v_warehouse_id AND product_id = v_item.product_id;
            END LOOP;
        END IF;

        RETURN NEW;
    END;
    $function$
