CREATE OR REPLACE FUNCTION public.create_supplier(p_name text, p_tax_code text, p_contact_person text, p_phone text, p_email text, p_address text, p_payment_term text, p_bank_account text, p_bank_name text, p_bank_holder text, p_delivery_method text, p_lead_time integer, p_status text, p_notes text)
 RETURNS bigint
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_supplier_id BIGINT;
    v_bank_bin TEXT;
BEGIN
    -- LOGIC TỰ ĐỘNG TÌM BIN NGÂN HÀNG
    -- Tìm theo tên đầy đủ HOẶC tên viết tắt (short_name)
    IF p_bank_name IS NOT NULL AND p_bank_name <> '' THEN
        SELECT bin INTO v_bank_bin 
        FROM public.banks 
        WHERE name ILIKE p_bank_name 
           OR short_name ILIKE p_bank_name 
           OR code ILIKE p_bank_name
        LIMIT 1;
    END IF;

    -- Insert với bank_bin tự động
    INSERT INTO public.suppliers (
        name, tax_code, contact_person, phone, email, address, 
        payment_term, bank_account, bank_name, bank_holder, delivery_method, lead_time,
        status, notes, 
        bank_bin -- Cột mới
    )
    VALUES (
        p_name, p_tax_code, p_contact_person, p_phone, p_email, p_address, 
        p_payment_term, p_bank_account, p_bank_name, p_bank_holder, p_delivery_method, p_lead_time,
        p_status, p_notes,
        v_bank_bin -- Giá trị tự động tìm được
    )
    RETURNING id INTO v_supplier_id;
    
    RETURN v_supplier_id;
END;
$function$
