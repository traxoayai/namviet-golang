CREATE OR REPLACE FUNCTION public.create_medical_visit(p_appointment_id uuid, p_customer_id bigint, p_data jsonb)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_visit_id UUID;
    v_doctor_id UUID;
    v_visit_status TEXT;
    v_sync_status TEXT;
BEGIN
    v_doctor_id := auth.uid();
    
    -- Lấy trạng thái gửi lên từ FE
    v_visit_status := COALESCE(p_data->>'status', 'in_progress');

    -- [CORE FIX ROUTING]: ĐIỀU HƯỚNG BỆNH NHÂN DỰA VÀO TRẠNG THÁI BÁC SĨ TRUYỀN XUỐNG
    IF v_visit_status = 'ready_for_vaccine' THEN
        v_sync_status := 'waiting_vaccination'; -- Bẻ lái sang Trạm Y tá Tiêm!
    ELSIF v_visit_status = 'ready_for_procedure' THEN
        v_sync_status := 'waiting_procedure';   -- Bẻ lái sang Trạm Thủ thuật!
    ELSIF v_visit_status = 'finished' THEN
        v_sync_status := 'completed';           -- Ra về / Chờ lấy thuốc
    ELSE
        v_sync_status := 'examining';           -- Đang khám / Lưu nháp
    END IF;

    -- [LOGIC CŨ]: INSERT ... ON CONFLICT (Upsert) để lưu toàn bộ dữ liệu khám
    INSERT INTO public.medical_visits (
        appointment_id, customer_id, doctor_id, created_by, status,
        pulse, temperature, sp02, respiratory_rate, bp_systolic, bp_diastolic,
        weight, height, bmi, head_circumference, birth_weight, birth_height,
        symptoms, examination_summary, diagnosis, icd_code, doctor_notes,
        fontanelle, reflexes, jaundice, feeding_status,
        dental_status, motor_development, language_development,
        puberty_stage, scoliosis_status, visual_acuity_left, visual_acuity_right,
        lifestyle_alcohol, lifestyle_smoking,
        red_flags, vac_screening
    )
    VALUES (
        p_appointment_id, p_customer_id, v_doctor_id, v_doctor_id, v_visit_status,
        (p_data->>'pulse')::INT, (p_data->>'temperature')::NUMERIC, (p_data->>'sp02')::INT, (p_data->>'respiratory_rate')::INT,
        (p_data->>'bp_systolic')::INT, (p_data->>'bp_diastolic')::INT,
        (p_data->>'weight')::NUMERIC, (p_data->>'height')::NUMERIC, (p_data->>'bmi')::NUMERIC,
        (p_data->>'head_circumference')::NUMERIC, (p_data->>'birth_weight')::NUMERIC, (p_data->>'birth_height')::NUMERIC,
        p_data->>'symptoms', p_data->>'examination_summary', p_data->>'diagnosis', p_data->>'icd_code', p_data->>'doctor_notes',
        p_data->>'fontanelle', p_data->>'reflexes', p_data->>'jaundice', p_data->>'feeding_status',
        p_data->>'dental_status', p_data->>'motor_development', p_data->>'language_development',
        p_data->>'puberty_stage', p_data->>'scoliosis_status', p_data->>'visual_acuity_left', p_data->>'visual_acuity_right',
        (p_data->>'lifestyle_alcohol')::BOOLEAN, (p_data->>'lifestyle_smoking')::BOOLEAN,
        COALESCE(p_data->'red_flags', '[]'::jsonb),
        COALESCE(p_data->'vac_screening', '{}'::jsonb)
    )
    ON CONFLICT (appointment_id) 
    DO UPDATE SET
        updated_at = NOW(),
        updated_by = v_doctor_id,
        status = v_visit_status, -- Lưu trạng thái (in_progress, ready_for_vaccine, v.v...)
        
        -- Cập nhật lại toàn bộ các trường y lệnh
        pulse = EXCLUDED.pulse, temperature = EXCLUDED.temperature, sp02 = EXCLUDED.sp02,
        respiratory_rate = EXCLUDED.respiratory_rate, bp_systolic = EXCLUDED.bp_systolic, bp_diastolic = EXCLUDED.bp_diastolic,
        weight = EXCLUDED.weight, height = EXCLUDED.height, bmi = EXCLUDED.bmi,
        head_circumference = EXCLUDED.head_circumference, birth_weight = EXCLUDED.birth_weight, birth_height = EXCLUDED.birth_height,
        symptoms = EXCLUDED.symptoms, examination_summary = EXCLUDED.examination_summary,
        diagnosis = EXCLUDED.diagnosis, icd_code = EXCLUDED.icd_code, doctor_notes = EXCLUDED.doctor_notes,
        fontanelle = EXCLUDED.fontanelle, reflexes = EXCLUDED.reflexes, jaundice = EXCLUDED.jaundice, feeding_status = EXCLUDED.feeding_status,
        dental_status = EXCLUDED.dental_status, motor_development = EXCLUDED.motor_development, language_development = EXCLUDED.language_development,
        puberty_stage = EXCLUDED.puberty_stage, scoliosis_status = EXCLUDED.scoliosis_status,
        visual_acuity_left = EXCLUDED.visual_acuity_left, visual_acuity_right = EXCLUDED.visual_acuity_right,
        lifestyle_alcohol = EXCLUDED.lifestyle_alcohol, lifestyle_smoking = EXCLUDED.lifestyle_smoking,
        red_flags = EXCLUDED.red_flags, vac_screening = EXCLUDED.vac_screening
        
    RETURNING id INTO v_visit_id;

    -- [REAL-TIME SYNC]: Đồng bộ trạng thái sang Lịch hẹn & Hàng đợi (Bẻ lái tại đây)
    UPDATE public.appointments 
    SET status = v_sync_status::public.appointment_status 
    WHERE id = p_appointment_id;
    
    UPDATE public.clinical_queues 
    SET status = v_sync_status::public.queue_status 
    WHERE appointment_id = p_appointment_id;

    RETURN v_visit_id;
END;
$function$
