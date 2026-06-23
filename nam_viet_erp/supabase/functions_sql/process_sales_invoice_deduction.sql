CREATE OR REPLACE FUNCTION public.process_sales_invoice_deduction(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_invoice_record RECORD;
    v_item JSONB;
    v_product_id BIGINT;
    v_unit_name TEXT;
    v_qty_input NUMERIC;
    v_vat_rate NUMERIC;
    
    v_conversion_rate INTEGER;
    v_base_unit_name TEXT;
    v_qty_deduct NUMERIC;
    v_current_balance NUMERIC;
BEGIN
    -- A. Lấy thông tin hóa đơn bán ra
    SELECT * INTO v_invoice_record FROM public.sales_invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóa đơn bán ra ID % không tồn tại', p_invoice_id; END IF;

    -- B. Duyệt từng dòng sản phẩm trên hóa đơn
    -- Giả sử cấu trúc JSON items: [{ "product_id": 1, "unit": "Hộp", "quantity": 5, "vat_rate": 8 }]
    -- (Sếp cần bảo Dev gửi đúng key 'unit' và 'vat_rate' trong json)
    
    -- Lưu ý: Cần xử lý linh động tên cột trong JSON (unit hoặc uom)
    FOR v_item IN SELECT * FROM jsonb_array_elements(COALESCE(v_invoice_record.items_json, '[]'::jsonb))
    LOOP
        v_product_id := (v_item->>'product_id')::BIGINT;
        v_unit_name  := COALESCE(v_item->>'unit', v_item->>'uom'); -- Đơn vị bán (Vỉ/Hộp)
        v_qty_input  := COALESCE((v_item->>'quantity')::NUMERIC, 0);
        v_vat_rate   := COALESCE((v_item->>'vat_rate')::NUMERIC, 0); -- Thuế suất muốn xuất

        IF v_product_id IS NOT NULL AND v_qty_input > 0 THEN
            
            -- 1. TÌM TỶ LỆ QUY ĐỔI (QUAN TRỌNG: HỘP -> VIÊN)
            v_conversion_rate := 1; -- Mặc định

            -- Tìm trong bảng đơn vị
            SELECT conversion_rate INTO v_conversion_rate 
            FROM public.product_units 
            WHERE product_id = v_product_id AND LOWER(unit_name) = LOWER(v_unit_name)
            LIMIT 1;

            -- Nếu không thấy (hoặc là base), thử check lại xem có phải base unit không
            IF v_conversion_rate IS NULL THEN
                 SELECT conversion_rate INTO v_conversion_rate
                 FROM public.product_units
                 WHERE product_id = v_product_id AND is_base = true
                 LIMIT 1;
            END IF;
            
            v_conversion_rate := COALESCE(v_conversion_rate, 1);

            -- 2. TÍNH SỐ LƯỢNG BASE CẦN TRỪ
            v_qty_deduct := v_qty_input * v_conversion_rate;

            -- 3. KIỂM TRA TỒN KHO VAT (Theo đúng thuế suất)
            SELECT quantity_balance INTO v_current_balance
            FROM public.vat_inventory_ledger
            WHERE product_id = v_product_id AND vat_rate = v_vat_rate
            FOR UPDATE; -- Khóa dòng để tránh tranh chấp

            IF v_current_balance IS NULL OR v_current_balance < v_qty_deduct THEN
                RAISE EXCEPTION 'Kho VAT không đủ hàng để xuất! Sản phẩm ID: %, Thuế: % %%. Cần: % (base), Tồn: % (base).', 
                                v_product_id, v_vat_rate, v_qty_deduct, COALESCE(v_current_balance, 0);
            END IF;

            -- 4. THỰC HIỆN TRỪ KHO
            UPDATE public.vat_inventory_ledger
            SET quantity_balance = quantity_balance - v_qty_deduct,
                updated_at = NOW()
            WHERE product_id = v_product_id AND vat_rate = v_vat_rate;
            
            -- (Lưu ý: Ta chưa trừ total_value_balance ở đây vì xuất hóa đơn bán ra thường theo giá bán, 
            -- còn ledger lưu giá vốn. Việc tính giá vốn xuất kho VAT phức tạp hơn (FIFO/Bình quân).
            -- Ở V1, ta chấp nhận chỉ quản lý chặt SỐ LƯỢNG để không bị xuất khống).
            
        END IF;
    END LOOP;
END;
$function$
