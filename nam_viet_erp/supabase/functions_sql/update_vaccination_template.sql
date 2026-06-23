CREATE OR REPLACE FUNCTION public.update_vaccination_template(p_id bigint, p_data jsonb, p_items jsonb)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_item JSONB;
BEGIN
    UPDATE public.vaccination_templates
    SET 
        name = COALESCE(p_data->>'name', name),
        description = COALESCE(p_data->>'description', description),
        min_age_months = (p_data->>'min_age_months')::INTEGER,
        max_age_months = (p_data->>'max_age_months')::INTEGER,
        status = COALESCE(p_data->>'status', status),
        updated_at = NOW()
    WHERE id = p_id;

    DELETE FROM public.vaccination_template_items WHERE template_id = p_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        INSERT INTO public.vaccination_template_items (template_id, product_id, shot_name, days_after_start, note)
        VALUES (
            p_id,
            (v_item->>'product_id')::BIGINT,
            v_item->>'shot_name',
            COALESCE((v_item->>'days_after_start')::INTEGER, 0),
            v_item->>'note'
        );
    END LOOP;

    RETURN TRUE;
END;
$function$
