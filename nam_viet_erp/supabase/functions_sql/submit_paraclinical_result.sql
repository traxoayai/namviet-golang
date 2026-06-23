CREATE OR REPLACE FUNCTION public.submit_paraclinical_result(p_request_id bigint, p_results_json jsonb DEFAULT NULL::jsonb, p_imaging_result text DEFAULT NULL::text, p_status text DEFAULT 'completed'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_current_status TEXT;
    v_visit_id UUID;
BEGIN
    -- Kiểm tra request tồn tại
    SELECT status, medical_visit_id INTO v_current_status, v_visit_id 
    FROM public.clinical_service_requests 
    WHERE id = p_request_id;

    IF v_current_status IS NULL THEN
        RAISE EXCEPTION 'Không tìm thấy yêu cầu chỉ định này (ID: %)', p_request_id;
    END IF;

    -- Update kết quả
    UPDATE public.clinical_service_requests
    SET 
        results_json = COALESCE(p_results_json, results_json),
        imaging_result = COALESCE(p_imaging_result, imaging_result),
        status = p_status,
        updated_at = NOW()
    WHERE id = p_request_id;

    -- Cập nhật timestamp cho Medical Visit cha để đánh dấu hồ sơ có thay đổi
    UPDATE public.medical_visits 
    SET updated_at = NOW() 
    WHERE id = v_visit_id;

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã lưu kết quả cận lâm sàng', 
        'request_id', p_request_id
    );
END;
$function$
