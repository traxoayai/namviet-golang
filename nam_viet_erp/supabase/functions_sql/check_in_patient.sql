CREATE OR REPLACE FUNCTION public.check_in_patient(p_customer_id bigint, p_doctor_id uuid DEFAULT NULL::uuid, p_priority text DEFAULT 'normal'::text, p_symptoms jsonb DEFAULT '[]'::jsonb, p_notes text DEFAULT NULL::text, p_service_ids bigint[] DEFAULT '{}'::bigint[], p_service_type text DEFAULT 'examination'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_queue_num INTEGER; 
    v_appt_id UUID; 
    v_queue_id BIGINT;
BEGIN
    -- Lấy số thứ tự (reset mỗi ngày)
    SELECT COALESCE(MAX(queue_number), 0) + 1 INTO v_queue_num 
    FROM public.clinical_queues 
    WHERE date(created_at) = CURRENT_DATE;

    -- TẠO LỊCH HẸN: Đã lưu được service_ids và service_type
    INSERT INTO public.appointments (
        customer_id, doctor_id, appointment_time, status, 
        symptoms, note, service_type, check_in_time, 
        service_ids -- [CORE LƯU DỮ LIỆU]
    ) 
    VALUES (
        p_customer_id, p_doctor_id, now(), 'waiting', 
        p_symptoms, p_notes, p_service_type::public.appointment_service_type, now(), 
        p_service_ids -- [CORE LƯU DỮ LIỆU]
    ) 
    RETURNING id INTO v_appt_id;
    
    -- XẾP HÀNG ĐỢI
    INSERT INTO public.clinical_queues (
        appointment_id, customer_id, doctor_id, queue_number, status, priority_level
    ) 
    VALUES (
        v_appt_id, p_customer_id, p_doctor_id, v_queue_num, 'waiting', p_priority::public.queue_priority
    ) 
    RETURNING id INTO v_queue_id;
    
    RETURN jsonb_build_object('success', true, 'queue_number', v_queue_num, 'queue_id', v_queue_id, 'appointment_id', v_appt_id);
END;
$function$
