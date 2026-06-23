CREATE OR REPLACE FUNCTION public.get_reception_queue(p_date date DEFAULT CURRENT_DATE, p_search text DEFAULT ''::text)
 RETURNS TABLE(id uuid, appointment_time timestamp with time zone, customer_id bigint, customer_name text, customer_phone text, customer_code text, customer_gender text, customer_yob integer, service_ids bigint[], room_id bigint, service_names text[], room_name text, priority text, doctor_name text, creator_name text, payment_status text, status text, contact_status text, service_type text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_text_part TEXT;
    v_phone_part TEXT;
BEGIN
    v_phone_part := regexp_replace(p_search, '[^0-9]', '', 'g');
    v_text_part := trim(regexp_replace(p_search, '[0-9]', '', 'g'));
    
    IF v_phone_part = '' THEN v_phone_part := NULL; END IF;
    IF v_text_part = '' THEN v_text_part := NULL; END IF;

    RETURN QUERY
    SELECT 
        a.id,
        a.appointment_time,
        c.id as customer_id,
        COALESCE(c.name, 'Khách vãng lai') as customer_name, 
        c.phone as customer_phone,
        c.customer_code,
        c.gender::text,
        CAST(EXTRACT(YEAR FROM c.dob) AS INTEGER) as customer_yob,
        
        COALESCE(a.service_ids, '{}') as service_ids,
        a.room_id,
        
        ARRAY(
            SELECT sp.name 
            FROM public.service_packages sp 
            WHERE sp.id = ANY(a.service_ids)
        ) as service_names,
        
        COALESCE(w.name, 'Chưa xếp phòng') as room_name,
        a.priority,
        COALESCE(u_doc.raw_user_meta_data->>'full_name', u_doc.email, 'Chưa chỉ định') as doctor_name,
        COALESCE(u_creator.raw_user_meta_data->>'full_name', u_creator.email, 'System') as creator_name,
        
        (
            SELECT o.payment_status 
            FROM public.orders o 
            WHERE o.customer_b2c_id = c.id 
              AND DATE(o.created_at AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_date 
            ORDER BY o.created_at DESC 
            LIMIT 1
        ) as payment_status,
        
        a.status::text, 
        a.contact_status,
        a.service_type::text -- [CORE BỔ SUNG LẤY DỮ LIỆU CỘT NÀY]
    FROM public.appointments a
    JOIN public.customers c ON a.customer_id = c.id
    LEFT JOIN auth.users u_doc ON a.doctor_id = u_doc.id 
    LEFT JOIN auth.users u_creator ON a.created_by = u_creator.id 
    LEFT JOIN public.warehouses w ON a.room_id = w.id 
    WHERE 
        DATE(a.appointment_time AT TIME ZONE 'Asia/Ho_Chi_Minh') = p_date
        AND (
            p_search = '' 
            OR (
                (v_text_part IS NULL OR c.name ILIKE '%' || v_text_part || '%') 
                AND 
                (v_phone_part IS NULL OR c.phone ILIKE '%' || v_phone_part || '%')
            )
        )
    ORDER BY 
        CASE WHEN a.priority = 'emergency' THEN 0 ELSE 1 END,
        a.appointment_time ASC;
END;
$function$
