CREATE OR REPLACE FUNCTION public.create_appointment_booking(p_customer_id bigint, p_doctor_id uuid DEFAULT NULL::uuid, p_time timestamp with time zone DEFAULT now(), p_symptoms jsonb DEFAULT '[]'::jsonb, p_note text DEFAULT NULL::text, p_type text DEFAULT 'examination'::text, p_status text DEFAULT 'confirmed'::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_id UUID;
    BEGIN
        -- Thực hiện Insert
        INSERT INTO public.appointments (
            customer_id, 
            doctor_id, 
            appointment_time, 
            symptoms, 
            note, 
            service_type, 
            status -- Cột trạng thái
        ) VALUES (
            p_customer_id, 
            p_doctor_id, 
            p_time, 
            p_symptoms, 
            p_note, 
            p_type::public.appointment_service_type, 
            p_status::public.appointment_status -- Ép kiểu sang Enum (pending, confirmed...)
        ) RETURNING id INTO v_id;

        RETURN jsonb_build_object('success', true, 'appointment_id', v_id);
    END;
    $function$
