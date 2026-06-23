CREATE OR REPLACE FUNCTION public.get_vaccination_template_details(p_id bigint)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_template RECORD;
    v_items JSON;
BEGIN
    SELECT * INTO v_template FROM public.vaccination_templates WHERE id = p_id;
    IF v_template IS NULL THEN RETURN NULL; END IF;

    SELECT json_agg(json_build_object(
        'id', i.id,
        'product_id', i.product_id,
        'product_name', p.name,
        'product_sku', p.sku, -- Thêm SKU cho dễ nhìn
        'shot_name', i.shot_name,
        'days_after_start', i.days_after_start,
        'note', i.note
    ) ORDER BY i.days_after_start ASC)
    INTO v_items
    FROM public.vaccination_template_items i
    LEFT JOIN public.products p ON i.product_id = p.id
    WHERE i.template_id = p_id;

    RETURN json_build_object(
        'template', row_to_json(v_template),
        'items', COALESCE(v_items, '[]'::json)
    );
END;
$function$
