CREATE OR REPLACE FUNCTION public.allocate_inbound_costs(p_receipt_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_shipping_fee NUMERIC;
        v_other_fee NUMERIC;
        v_total_fee NUMERIC;
        v_total_value NUMERIC;
        v_total_quantity NUMERIC;
        v_allocation_method TEXT;
        v_item RECORD;
        v_ratio NUMERIC;
        v_allocated_amt NUMERIC;
        v_final_cost NUMERIC;
    BEGIN
        -- 1. Lấy thông tin Phí từ Header
        SELECT COALESCE(shipping_fee, 0), COALESCE(other_fee, 0)
        INTO v_shipping_fee, v_other_fee
        FROM public.inventory_receipts
        WHERE id = p_receipt_id;

        v_total_fee := v_shipping_fee + v_other_fee;

        -- Nếu không có phí thì reset về 0 và thoát
        IF v_total_fee = 0 THEN
            UPDATE public.inventory_receipt_items
            SET allocated_cost = 0, final_unit_cost = unit_price
            WHERE receipt_id = p_receipt_id;
            
            RETURN jsonb_build_object('success', true, 'message', 'Không có chi phí phụ để phân bổ.');
        END IF;

        -- 2. Tính Tổng Giá Trị và Tổng Số Lượng của phiếu
        SELECT 
            SUM(quantity * unit_price), 
            SUM(quantity)
        INTO v_total_value, v_total_quantity
        FROM public.inventory_receipt_items
        WHERE receipt_id = p_receipt_id;

        -- 3. Quyết định phương pháp phân bổ
        IF v_total_value > 0 THEN
            v_allocation_method := 'VALUE'; -- Chia theo giá trị (Mặc định)
        ELSE
            v_allocation_method := 'QUANTITY'; -- Fallback: Chia theo số lượng (nếu toàn hàng tặng)
        END IF;

        -- 4. Thực hiện phân bổ từng dòng
        FOR v_item IN SELECT id, quantity, unit_price FROM public.inventory_receipt_items WHERE receipt_id = p_receipt_id
        LOOP
            IF v_allocation_method = 'VALUE' THEN
                -- Tỷ lệ = (Giá trị dòng / Tổng giá trị phiếu)
                v_ratio := (v_item.quantity * v_item.unit_price) / v_total_value;
            ELSE
                -- Tỷ lệ = (Số lượng dòng / Tổng số lượng phiếu)
                v_ratio := v_item.quantity / v_total_quantity;
            END IF;

            -- Tính tiền phí cho cả dòng -> Chia lại cho số lượng để ra đơn giá phí
            v_allocated_amt := (v_total_fee * v_ratio) / v_item.quantity;
            
            -- Giá vốn cuối = Giá nhập + Giá phí phân bổ
            v_final_cost := v_item.unit_price + v_allocated_amt;

            -- Update
            UPDATE public.inventory_receipt_items
            SET allocated_cost = v_allocated_amt,
                final_unit_cost = v_final_cost
            WHERE id = v_item.id;
        END LOOP;

        RETURN jsonb_build_object(
            'success', true, 
            'method', v_allocation_method,
            'total_fee_allocated', v_total_fee,
            'message', 'Đã phân bổ chi phí thành công theo phương pháp: ' || v_allocation_method
        );
    END;
    $function$
