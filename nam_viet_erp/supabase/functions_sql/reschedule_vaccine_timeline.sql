CREATE OR REPLACE FUNCTION public.reschedule_vaccine_timeline(p_record_id bigint, p_new_expected_date date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_record RECORD;
    v_delta_days INT;
    v_updated_count INT := 0;
BEGIN
    -- 1. Lấy mũi tiêm hiện tại (Bọc FOR UPDATE để tránh tranh chấp dữ liệu khi nhiều người thao tác)
    SELECT * INTO v_record FROM public.customer_vaccination_records WHERE id = p_record_id FOR UPDATE;
    
    IF v_record IS NULL THEN RAISE EXCEPTION 'Không tìm thấy lịch tiêm ID %', p_record_id; END IF;
    IF v_record.status != 'pending' THEN RAISE EXCEPTION 'Chỉ có thể dời lịch những mũi tiêm chưa thực hiện.'; END IF;

    -- 2. Tính số ngày bị lùi/tiến (Delta)
    v_delta_days := p_new_expected_date - v_record.expected_date;

    -- 3. UPDATE MŨI HIỆN TẠI (Sổ Tiêm + Lịch Hẹn)
    UPDATE public.customer_vaccination_records
    SET expected_date = p_new_expected_date, updated_at = NOW(), updated_by = auth.uid()
    WHERE id = p_record_id;
    
    IF v_record.appointment_id IS NOT NULL THEN
        UPDATE public.appointments 
        SET appointment_time = p_new_expected_date + interval '8 hours'
        WHERE id = v_record.appointment_id;
    END IF;
    
    v_updated_count := 1;

    -- 4. TỊNH TIẾN CÁC MŨI TIẾP THEO (Nếu nằm trong 1 Gói tiêm)
    IF v_record.package_id IS NOT NULL AND v_delta_days != 0 THEN
        
        -- A. Tịnh tiến Sổ tiêm trước
        UPDATE public.customer_vaccination_records
        SET 
            expected_date = expected_date + v_delta_days,
            updated_at = NOW(),
            updated_by = auth.uid()
        WHERE customer_id = v_record.customer_id
          AND package_id = v_record.package_id
          AND dose_number > v_record.dose_number
          AND status = 'pending';
          
        -- B. Tịnh tiến đồng loạt Lịch hẹn tương ứng
        UPDATE public.appointments a
        SET appointment_time = r.expected_date + interval '8 hours' -- [CORE TỐI ƯU]: Ép chuẩn 8h sáng theo ngày mới nhất
        FROM public.customer_vaccination_records r
        WHERE r.appointment_id = a.id
          AND r.customer_id = v_record.customer_id
          AND r.package_id = v_record.package_id
          AND r.dose_number > v_record.dose_number
          AND r.status = 'pending';
          
    END IF;

    RETURN jsonb_build_object('success', true, 'delta_days', v_delta_days, 'message', 'Đã tịnh tiến Sổ tiêm và Lịch hẹn thành công');
END;
$function$
