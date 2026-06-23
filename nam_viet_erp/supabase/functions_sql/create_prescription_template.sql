CREATE OR REPLACE FUNCTION public.create_prescription_template(p_data jsonb, p_items jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_new_id BIGINT;
    v_item JSONB;
BEGIN
    -- Insert Header
    INSERT INTO public.prescription_templates (name, diagnosis, note, status)
    VALUES (
        p_data->>'name',
        p_data->>'diagnosis',
        p_data->>'note',
        COALESCE(p_data->>'status', 'active')
    )
    RETURNING id INTO v_new_id;

    -- Insert Items
    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.prescription_template_items (template_id, product_id, quantity, usage_instruction)
        VALUES (
            v_new_id,
            (v_item->>'product_id')::BIGINT, -- <-- QUAN TRỌNG: Ép kiểu sang BIGINT
            (v_item->>'quantity')::INTEGER,
            v_item->>'usage_instruction'
        );
    END LOOP;

    RETURN v_new_id;
END;
$function$
