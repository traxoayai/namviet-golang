CREATE OR REPLACE FUNCTION public.generate_vaccine_timeline(p_customer_id bigint, p_start_date date, p_order_id uuid DEFAULT NULL::uuid, p_package_id bigint DEFAULT NULL::bigint, p_product_id bigint DEFAULT NULL::bigint, p_consulted_by uuid DEFAULT auth.uid())
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item RECORD;
    v_dose_count INT := 1;
    v_inserted_count INT := 0;
    v_expected_date DATE;
    v_appt_id UUID;
    v_service_array BIGINT[];
    v_temp_svc_id BIGINT; -- Biến tạm để hứng ID, khắc phục lỗi 42804
BEGIN
    IF p_package_id IS NOT NULL THEN
        -- A. Kịch bản mua GÓI TIÊM
        v_service_array := ARRAY[p_package_id];

        FOR v_item IN 
            SELECT item_id as product_id, quantity, schedule_days 
            FROM public.service_package_items 
            WHERE package_id = p_package_id 
            ORDER BY schedule_days ASC
        LOOP
            v_expected_date := p_start_date + COALESCE(v_item.schedule_days, 0);

            -- TẠO LỊCH HẸN TỰ ĐỘNG
            INSERT INTO public.appointments (
                customer_id, appointment_time, status, service_type, note, created_by, service_ids
            ) VALUES (
                p_customer_id, v_expected_date + interval '8 hours', 'pending', 'vaccination', 'Lịch tiêm tự động từ Gói', p_consulted_by, v_service_array
            ) RETURNING id INTO v_appt_id;

            -- Đưa vào Sổ tiêm
            INSERT INTO public.customer_vaccination_records (
                customer_id, order_id, package_id, product_id, dose_number, 
                expected_date, status, consulted_by, appointment_id
            ) VALUES (
                p_customer_id, p_order_id, p_package_id, v_item.product_id, v_dose_count,
                v_expected_date, 'pending', p_consulted_by, v_appt_id
            );
            
            v_dose_count := v_dose_count + 1;
            v_inserted_count := v_inserted_count + 1;
        END LOOP;

    ELSIF p_product_id IS NOT NULL THEN
        -- B. Kịch bản mua MŨI LẺ
        
        -- Dùng biến tạm để hứng ID dịch vụ
        SELECT id INTO v_temp_svc_id 
        FROM public.service_packages 
        WHERE type = 'service' AND clinical_category = 'vaccination' 
          AND id IN (SELECT package_id FROM public.service_package_items WHERE item_id = p_product_id)
        LIMIT 1;

        -- Gán vào mảng an toàn
        v_service_array := ARRAY[v_temp_svc_id];

        SELECT COALESCE(MAX(dose_number), 0) + 1 INTO v_dose_count 
        FROM public.customer_vaccination_records 
        WHERE customer_id = p_customer_id AND product_id = p_product_id;

        v_expected_date := p_start_date;

        -- Tạo Lịch hẹn tự động
        INSERT INTO public.appointments (
            customer_id, appointment_time, status, service_type, note, created_by, service_ids
        ) VALUES (
            p_customer_id, v_expected_date + interval '8 hours', 'pending', 'vaccination', 'Lịch tiêm Mũi lẻ', p_consulted_by, v_service_array
        ) RETURNING id INTO v_appt_id;

        -- Đưa vào Sổ tiêm
        INSERT INTO public.customer_vaccination_records (
            customer_id, order_id, product_id, dose_number, 
            expected_date, status, consulted_by, appointment_id
        ) VALUES (
            p_customer_id, p_order_id, p_product_id, v_dose_count,
            v_expected_date, 'pending', p_consulted_by, v_appt_id
        );
        
        v_inserted_count := 1;
    ELSE
        RAISE EXCEPTION 'Phải cung cấp package_id hoặc product_id';
    END IF;

    RETURN jsonb_build_object('success', true, 'inserted_count', v_inserted_count);
END;
$function$
