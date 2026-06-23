CREATE OR REPLACE FUNCTION public.doctor_approve_vaccination(p_medical_visit_id uuid, p_doctor_id uuid DEFAULT auth.uid(), p_notes text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_appt_id UUID;
BEGIN
    -- 1. Chuyển trạng thái Phiếu khám
    UPDATE public.medical_visits
    SET 
        status = 'waiting_vaccination',
        doctor_notes = COALESCE(p_notes, doctor_notes),
        doctor_id = COALESCE(p_doctor_id, doctor_id),
        updated_at = NOW(),
        updated_by = auth.uid()
    WHERE id = p_medical_visit_id
    RETURNING appointment_id INTO v_appt_id;

    -- 2. Đẩy ra Màn hình Tivi / Hàng chờ phòng tiêm
    IF v_appt_id IS NOT NULL THEN
        UPDATE public.clinical_queues 
        SET status = 'waiting' -- Quay lại chờ, nhưng lúc này hệ thống UI sẽ biết là chờ tiêm
        WHERE appointment_id = v_appt_id;
    END IF;

    RETURN jsonb_build_object('success', true, 'message', 'Đã duyệt: Bệnh nhân đủ điều kiện tiêm');
END;
$function$
