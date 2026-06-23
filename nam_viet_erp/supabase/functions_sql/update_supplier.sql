CREATE OR REPLACE FUNCTION public.update_supplier(p_id bigint, p_name text, p_tax_code text, p_contact_person text, p_phone text, p_email text, p_address text, p_payment_term text, p_bank_account text, p_bank_name text, p_bank_holder text, p_delivery_method text, p_lead_time integer, p_status text, p_notes text)
 RETURNS void
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_bank_bin TEXT;
BEGIN
    -- LOGIC TỰ ĐỘNG TÌM BIN (Giống hàm Create)
    IF p_bank_name IS NOT NULL AND p_bank_name <> '' THEN
        SELECT bin INTO v_bank_bin 
        FROM public.banks 
        WHERE name ILIKE p_bank_name 
           OR short_name ILIKE p_bank_name 
           OR code ILIKE p_bank_name
        LIMIT 1;
    END IF;

    UPDATE public.suppliers
    SET
        name = p_name,
        tax_code = p_tax_code,
        contact_person = p_contact_person,
        phone = p_phone,
        email = p_email,
        address = p_address,
        payment_term = p_payment_term,
        bank_account = p_bank_account,
        bank_name = p_bank_name,
        bank_holder = p_bank_holder,
        delivery_method = p_delivery_method,
        lead_time = p_lead_time,
        status = p_status,
        notes = p_notes,
        bank_bin = v_bank_bin -- Cập nhật tự động
    WHERE id = p_id;
END;
$function$
