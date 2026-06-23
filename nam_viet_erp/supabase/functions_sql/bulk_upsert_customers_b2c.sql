CREATE OR REPLACE FUNCTION public.bulk_upsert_customers_b2c(p_customers_array jsonb[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    customer_data JSONB;
    v_type TEXT;
    v_customer_code_from_excel TEXT;
    v_final_customer_code TEXT;
    v_customer_id BIGINT;
    v_initial_debt NUMERIC;
    v_debt_order_id UUID;
    v_paid_amount NUMERIC;
BEGIN
    FOREACH customer_data IN ARRAY p_customers_array
    LOOP
        v_type := customer_data->>'type';
        v_customer_code_from_excel := customer_data->>'customer_code';

        -- 1. Tạo/Lấy Mã KH
        SELECT COALESCE(NULLIF(TRIM(v_customer_code_from_excel), ''), 'KH-' || (nextval(pg_get_serial_sequence('public.customers', 'id')) + 10000)) 
        INTO v_final_customer_code;

        -- 2. UPSERT Khách hàng (FULL UPDATE)
        IF v_type = 'CaNhan' THEN
            INSERT INTO public.customers (
                customer_code, name, type, phone, loyalty_points, status,
                email, address, dob, gender
            ) VALUES (
                v_final_customer_code, customer_data->>'name', 'CaNhan', customer_data->>'phone',
                (customer_data->>'loyalty_points')::INT, 'active',
                customer_data->>'email', customer_data->>'address',
                (customer_data->>'dob')::DATE, (customer_data->>'gender')::public.customer_gender
            )
            ON CONFLICT (customer_code) DO UPDATE SET 
                name = EXCLUDED.name, phone = EXCLUDED.phone, 
                address = EXCLUDED.address, email = EXCLUDED.email, -- [CORE FIX] Update thêm
                updated_at = now()
            RETURNING id INTO v_customer_id;

        ELSIF v_type = 'ToChuc' THEN
            INSERT INTO public.customers (
                customer_code, name, type, phone, tax_code, 
                contact_person_name, contact_person_phone, loyalty_points, status
            ) VALUES (
                v_final_customer_code, customer_data->>'name', 'ToChuc', customer_data->>'phone',
                customer_data->>'tax_code', customer_data->>'contact_person_name', 
                customer_data->>'contact_person_phone', (customer_data->>'loyalty_points')::INT, 'active'
            )
            ON CONFLICT (customer_code) DO UPDATE SET 
                name = EXCLUDED.name, phone = EXCLUDED.phone, tax_code = EXCLUDED.tax_code,
                contact_person_name = EXCLUDED.contact_person_name, -- [CORE FIX] Update thêm
                updated_at = now()
            RETURNING id INTO v_customer_id;
        END IF;

        -- 3. XỬ LÝ NỢ ĐẦU KỲ (LOGIC THÔNG MINH)
        v_initial_debt := COALESCE((customer_data->>'initial_debt')::NUMERIC, 0);
        
        IF v_initial_debt > 0 THEN
            SELECT id, paid_amount INTO v_debt_order_id, v_paid_amount
            FROM public.orders 
            WHERE code = 'DEBT-INIT-' || v_final_customer_code;

            IF v_debt_order_id IS NULL THEN
                -- CHƯA CÓ -> TẠO MỚI
                INSERT INTO public.orders (
                    code, customer_b2c_id, creator_id, status, total_amount, final_amount, 
                    paid_amount, payment_status, note, order_type
                ) VALUES (
                    'DEBT-INIT-' || v_final_customer_code, v_customer_id, auth.uid(), 'COMPLETED', 
                    v_initial_debt, v_initial_debt, 0, 'unpaid', 
                    'Nợ tồn đọng đầu kỳ (Import Excel)', 'opening_debt'
                );
            ELSE
                -- ĐÃ CÓ -> CHECK VÀ SỬA
                IF v_paid_amount = 0 THEN
                    UPDATE public.orders
                    SET total_amount = v_initial_debt,
                        final_amount = v_initial_debt,
                        updated_at = NOW()
                    WHERE id = v_debt_order_id;
                END IF;
            END IF;
        END IF;

    END LOOP;
END;
$function$
