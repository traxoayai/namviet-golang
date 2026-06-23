CREATE OR REPLACE FUNCTION public.import_suppliers_bulk(p_suppliers jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
    v_supplier_id BIGINT;
    v_count INT := 0;
    v_debt NUMERIC;
    v_trans_code TEXT;
BEGIN
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_suppliers)
    LOOP
        -- 1. Insert Supplier (Bỏ cột 'code')
        INSERT INTO public.suppliers (
            name, 
            tax_code, 
            address,
            contact_person, 
            phone, 
            email, 
            
            -- Thông tin Ngân hàng
            bank_name,
            bank_account,
            bank_holder,
            
            -- Thông tin Vận hành
            payment_term,
            delivery_method,
            
            status, 
            notes, 
            created_at
        ) VALUES (
            v_item->>'name',
            v_item->>'tax_code',
            v_item->>'address',
            v_item->>'contact_person',
            v_item->>'phone',
            v_item->>'email',
            
            v_item->>'bank_name',
            v_item->>'bank_account',
            v_item->>'bank_holder',
            
            v_item->>'payment_term', -- Lưu chuỗi text (VD: "30 ngày", "Gối đầu")
            v_item->>'delivery_method',
            
            'active', 
            v_item->>'notes',
            NOW()
        )
        RETURNING id INTO v_supplier_id;

        -- 2. Xử lý Công nợ đầu kỳ (Nếu có)
        BEGIN
            v_debt := COALESCE((v_item->>'current_debt')::NUMERIC, 0);
        EXCEPTION WHEN OTHERS THEN
            v_debt := 0; -- Nếu parse lỗi thì coi như 0
        END;

        IF v_debt > 0 THEN
            -- Sinh mã giao dịch tự động
            v_trans_code := 'CN-NCC-' || TO_CHAR(NOW(), 'YYMMDD') || '-' || floor(random() * 1000)::text;

            INSERT INTO public.finance_transactions (
                code,
                partner_type, 
                partner_id, 
                partner_name_cache, -- Cache tên để hiển thị nhanh
                amount, 
                flow, 
                business_type, 
                status, 
                description, 
                created_by,
                created_at,
                fund_account_id -- Bắt buộc (Lấy quỹ mặc định ID=1 hoặc NULL tùy logic)
            ) VALUES (
                v_trans_code,
                'supplier', 
                v_supplier_id::TEXT, 
                v_item->>'name', -- Cache tên NCC
                v_debt, 
                'out', -- Flow OUT (Nợ phải trả)
                'opening_balance', -- Loại: Dư nợ đầu kỳ
                'completed', -- Đã ghi nhận
                'Dư nợ đầu kỳ (Import Excel)',
                auth.uid(),
                NOW(),
                1 -- [HARDCODE TEMPORARY]: Gán tạm vào Quỹ Tiền Mặt (hoặc Sếp cần tạo 1 Quỹ ảo "Công nợ"?) -> Tạm để 1 để ko lỗi constraint
            );
        END IF;

        v_count := v_count + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'count', v_count);
END;
$function$
