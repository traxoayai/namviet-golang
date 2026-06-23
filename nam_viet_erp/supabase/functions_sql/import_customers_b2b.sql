CREATE OR REPLACE FUNCTION public.import_customers_b2b(p_customers_array jsonb[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        customer_data JSONB;
        v_customer_code_from_excel TEXT;
        v_final_customer_code TEXT;
        v_customer_b2b_id BIGINT;
        v_sales_staff_id UUID;
        v_initial_debt NUMERIC;
        v_success_count INT := 0;
    BEGIN
        FOREACH customer_data IN ARRAY p_customers_array
        LOOP
            -- A. TÌM NHÂN VIÊN SALE (Qua Email)
            v_sales_staff_id := NULL;
            IF customer_data->>'sales_staff_email' IS NOT NULL AND customer_data->>'sales_staff_email' <> '' THEN
                SELECT id INTO v_sales_staff_id 
                FROM public.users 
                WHERE email = TRIM(customer_data->>'sales_staff_email')
                LIMIT 1;
            END IF;

            -- B. XỬ LÝ MÃ KHÁCH HÀNG
            v_customer_code_from_excel := customer_data->>'customer_code';
            
            -- Nếu Excel rỗng mã -> Tự sinh B2B-XXXXX
            SELECT COALESCE(
                NULLIF(TRIM(v_customer_code_from_excel), ''), 
                'B2B-' || (nextval(pg_get_serial_sequence('public.customers_b2b', 'id')) + 10000)
            ) INTO v_final_customer_code;

            -- C. UPSERT KHÁCH HÀNG (Bảng customers_b2b)
            INSERT INTO public.customers_b2b (
                customer_code, name, tax_code, debt_limit, payment_term, 
                sales_staff_id, status, phone, email, vat_address, shipping_address,
                bank_name, bank_account_name, bank_account_number,
                loyalty_points
            ) VALUES (
                v_final_customer_code,
                customer_data->>'name',
                customer_data->>'tax_code',
                COALESCE((customer_data->>'debt_limit')::NUMERIC, 0),
                COALESCE((customer_data->>'payment_term')::INT, 0),
                v_sales_staff_id,
                'active',
                customer_data->>'phone',
                customer_data->>'email',
                customer_data->>'address', 
                customer_data->>'address',
                customer_data->>'bank_name',
                customer_data->>'bank_account_name',
                customer_data->>'bank_account_number',
                0 
            )
            ON CONFLICT (customer_code) 
            DO UPDATE SET
                name = EXCLUDED.name,
                phone = EXCLUDED.phone,
                email = EXCLUDED.email,
                updated_at = now()
            RETURNING id INTO v_customer_b2b_id;

            -- D. XỬ LÝ LIÊN HỆ
            IF customer_data->>'contact_person_name' IS NOT NULL THEN
                INSERT INTO public.customer_b2b_contacts (
                    customer_b2b_id, name, phone, position, is_primary
                ) VALUES (
                    v_customer_b2b_id,
                    customer_data->>'contact_person_name',
                    COALESCE(customer_data->>'contact_person_phone', customer_data->>'phone'),
                    'Liên hệ chính',
                    true
                )
                ON CONFLICT DO NOTHING; 
            END IF;

            -- E. XỬ LÝ NỢ CŨ (MIGRATION ORDER) 
            -- Logic: Tạo đơn hàng đã giao nhưng chưa trả tiền (Unpaid)
            v_initial_debt := COALESCE((customer_data->>'initial_debt')::NUMERIC, 0);
            
            IF v_initial_debt > 0 THEN
                INSERT INTO public.orders (
                    code,
                    customer_id,        -- Link vào khách B2B
                    customer_b2c_id,    -- NULL (Vì đây là B2B)
                    
                    -- [CÁC CỘT QUAN TRỌNG SẾP ĐÃ CONFIRM]
                    order_type,         -- 'B2B'
                    status,             -- 'DELIVERED' (Đã giao hàng)
                    payment_status,     -- 'unpaid' (Chưa trả -> Nợ)
                    
                    total_amount,
                    final_amount,
                    paid_amount,        -- = 0
                    discount_amount,
                    shipping_fee,
                    
                    payment_method,     -- 'debt' (Ghi nợ)
                    
                    -- [QUAN TRỌNG]: Set deposited để KHÔNG hiện ở màn hình "Nộp tiền" của nhân viên
                    remittance_status,  
                    
                    created_at,
                    updated_at,
                    note
                ) VALUES (
                    'MIGRATE-' || v_final_customer_code,
                    v_customer_b2b_id,
                    NULL,
                    'B2B',              -- order_type
                    'DELIVERED',        -- status
                    'unpaid',           -- payment_status
                    v_initial_debt,
                    v_initial_debt,
                    0,                  -- paid_amount
                    0, 0,
                    'debt',             -- payment_method
                    'deposited',        -- remittance_status (Đã xử lý xong tiền nong)
                    NOW(),
                    NOW(),
                    'Dư nợ đầu kỳ chuyển đổi hệ thống (Sapo Migration)'
                )
                ON CONFLICT (code) DO NOTHING;
            END IF;

            v_success_count := v_success_count + 1;
        END LOOP;

        RETURN jsonb_build_object('success', true, 'count', v_success_count);
    END;
    $function$
