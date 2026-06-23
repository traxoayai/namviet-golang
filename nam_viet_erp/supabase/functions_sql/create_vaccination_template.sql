CREATE OR REPLACE FUNCTION public.create_vaccination_template(p_data jsonb, p_items jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_new_id BIGINT;
    v_item JSONB;
BEGIN
    INSERT INTO public.vaccination_templates (name, description, min_age_months, max_age_months, status)
    VALUES (
        p_data->>'name',
        p_data->>'description',
        (p_data->>'min_age_months')::INTEGER,
        (p_data->>'max_age_months')::INTEGER,
        COALESCE(p_data->>'status', 'active')
    )
    RETURNING id INTO v_new_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.vaccination_template_items (template_id, product_id, shot_name, days_after_start, note)
        VALUES (
            v_new_id,
            (v_item->>'product_id')::BIGINT,
            v_item->>'shot_name',
            COALESCE((v_item->>'days_after_start')::INTEGER, 0),
            v_item->>'note'
        );
    END LOOP;

    RETURN v_new_id;
END;
$function$
