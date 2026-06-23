CREATE OR REPLACE FUNCTION public.create_full_supplier_program(p_program_data jsonb, p_groups_data jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_program_id BIGINT;
    v_group JSONB;
    v_group_id BIGINT;
    v_prod_id BIGINT;
BEGIN
    -- A. Insert Header
    INSERT INTO public.supplier_programs (
        supplier_id, code, name, type, 
        valid_from, valid_to, status, 
        document_code, attachment_url, description
    ) VALUES (
        (p_program_data->>'supplier_id')::BIGINT,
        p_program_data->>'code',
        p_program_data->>'name',
        (p_program_data->>'type')::public.supplier_program_type,
        (p_program_data->>'valid_from')::DATE,
        (p_program_data->>'valid_to')::DATE,
        'active',
        p_program_data->>'document_code',
        p_program_data->>'attachment_url',
        p_program_data->>'description'
    ) RETURNING id INTO v_program_id;

    -- B. Loop Insert Groups
    FOR v_group IN SELECT * FROM jsonb_array_elements(p_groups_data)
    LOOP
        INSERT INTO public.supplier_program_groups (
            program_id, name, rule_type, rules, price_basis
        ) VALUES (
            v_program_id,
            v_group->>'name',
            v_group->>'rule_type',
            v_group->'rules',
            COALESCE(v_group->>'price_basis', 'pre_vat')
        ) RETURNING id INTO v_group_id;

        -- C. Loop Insert Products (Scope)
        -- Sử dụng INSERT SELECT UNNEST để tối ưu hiệu năng thay vì loop từng dòng
        INSERT INTO public.supplier_program_products (group_id, product_id)
        SELECT v_group_id, (value::BIGINT)
        FROM jsonb_array_elements_text(v_group->'product_ids');
    END LOOP;

    RETURN v_program_id;
END;
$function$
