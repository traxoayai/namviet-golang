CREATE OR REPLACE FUNCTION public.update_prescription_template(p_id bigint, p_data jsonb, p_items jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
BEGIN
    -- Update Header
    UPDATE public.prescription_templates
    SET 
        name = COALESCE(p_data->>'name', name),
        diagnosis = COALESCE(p_data->>'diagnosis', diagnosis),
        note = COALESCE(p_data->>'note', note),
        status = COALESCE(p_data->>'status', status),
        updated_at = NOW()
    WHERE id = p_id;

    -- Replace Items
    DELETE FROM public.prescription_template_items WHERE template_id = p_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.prescription_template_items (template_id, product_id, quantity, usage_instruction)
        VALUES (
            p_id,
            (v_item->>'product_id')::BIGINT, -- <-- QUAN TRỌNG: Ép kiểu sang BIGINT
            (v_item->>'quantity')::INTEGER,
            v_item->>'usage_instruction'
        );
    END LOOP;

    RETURN TRUE;
END;
$function$
