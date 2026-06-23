CREATE OR REPLACE FUNCTION public.get_nurse_execution_queue(p_date date DEFAULT CURRENT_DATE)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_result JSONB;
BEGIN
    SELECT COALESCE(jsonb_agg(
        jsonb_build_object(
            'appointment_id', a.id,
            -- [FIX 1]: Xử lý an toàn nếu không có Số thứ tự
            'queue_number', COALESCE(cq.queue_number, 0), 
            'customer_id', c.id,
            'customer_name', c.name,
            'customer_phone', c.phone,
            'gender', c.gender,
            'yob', EXTRACT(YEAR FROM c.dob),
            'status', a.status,
            'service_type', a.service_type,
            
            'red_flags', COALESCE(mv.red_flags, '[]'::jsonb),
            'doctor_notes', mv.doctor_notes,

            'vaccines', (
                SELECT COALESCE(jsonb_agg(jsonb_build_object(
                    'record_id', cvr.id,
                    'product_id', p.id,
                    'product_name', p.name,
                    'sku', p.sku,
                    'barcode', p.barcode,
                    'dose_number', cvr.dose_number,
                    'status', cvr.status
                )), '[]'::jsonb)
                FROM public.customer_vaccination_records cvr
                JOIN public.products p ON cvr.product_id = p.id
                WHERE cvr.appointment_id = a.id
            ),

            'procedures', (
                SELECT COALESCE(jsonb_agg(jsonb_build_object(
                    'request_id', csr.id,
                    'service_name', csr.service_name_snapshot,
                    'status', csr.status
                )), '[]'::jsonb)
                FROM public.clinical_service_requests csr
                WHERE csr.medical_visit_id = mv.id 
                  AND csr.category = 'procedure'
            )
        )
    ORDER BY 
        CASE WHEN a.status = 'observing' THEN 1 ELSE 0 END, 
        -- Sắp xếp an toàn: Không có số thứ tự thì đẩy xuống cuối (999)
        COALESCE(cq.queue_number, 999) ASC
    ), '[]'::jsonb) INTO v_result

    FROM public.appointments a
    -- [FIX 2 CỐT LÕI]: Đổi INNER JOIN thành LEFT JOIN
    LEFT JOIN public.clinical_queues cq ON a.id = cq.appointment_id 
    JOIN public.customers c ON a.customer_id = c.id
    LEFT JOIN public.medical_visits mv ON mv.appointment_id = a.id
    WHERE 
        DATE(a.appointment_time AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_date
        AND a.status IN ('waiting_vaccination', 'waiting_procedure', 'observing');

    RETURN v_result;
END;
$function$
