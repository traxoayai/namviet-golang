CREATE OR REPLACE FUNCTION public.update_customer_b2c(p_id bigint, p_customer_data jsonb, p_guardians jsonb DEFAULT NULL::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_guardian JSONB;
BEGIN
    -- 1. Cập nhật bảng customers
    UPDATE public.customers
    SET
        name = p_customer_data->>'name',
        type = (p_customer_data->>'type')::public.customer_b2c_type,
        phone = p_customer_data->>'phone',
        email = p_customer_data->>'email',
        address = p_customer_data->>'address',
        
        -- 'CaNhan' fields
        dob = (p_customer_data->>'dob')::DATE,
        gender = (p_customer_data->>'gender')::public.customer_gender,
        cccd = p_customer_data->>'cccd',
        cccd_issue_date = (p_customer_data->>'cccd_issue_date')::DATE,
        avatar_url = p_customer_data->>'avatar_url',
        occupation = p_customer_data->>'occupation',
        lifestyle_habits = p_customer_data->>'lifestyle_habits',
        allergies = p_customer_data->>'allergies',
        medical_history = p_customer_data->>'medical_history',
        status = (p_customer_data->>'status')::public.account_status,
        
        -- 'ToChuc' fields
        tax_code = p_customer_data->>'tax_code',
        contact_person_name = p_customer_data->>'contact_person_name',
        contact_person_phone = p_customer_data->>'contact_person_phone',
        
        -- [QUAN TRỌNG] Ghi nhận người sửa để Trigger tính KPI
        -- Logic: Lấy từ payload gửi lên, nếu không có thì lấy user đang đăng nhập (auth.uid)
        updated_by = COALESCE((p_customer_data->>'updated_by')::uuid, auth.uid()),
        
        updated_at = now()
    WHERE id = p_id;

    -- 2. Xóa sạch và thêm lại Người Giám hộ (Logic cũ giữ nguyên)
    DELETE FROM public.customer_guardians WHERE customer_id = p_id;
    
    IF p_guardians IS NOT NULL AND (p_customer_data->>'type')::public.customer_b2c_type = 'CaNhan' THEN
        FOR v_guardian IN SELECT * FROM jsonb_array_elements(p_guardians)
        LOOP
            INSERT INTO public.customer_guardians (customer_id, guardian_id, relationship)
            VALUES (
                p_id,
                (v_guardian->>'guardian_id')::BIGINT,
                v_guardian->>'relationship'
            )
            ON CONFLICT (customer_id, guardian_id) DO NOTHING;
        END LOOP;
    END IF;
END;
$function$
