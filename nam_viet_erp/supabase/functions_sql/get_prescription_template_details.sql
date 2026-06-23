CREATE OR REPLACE FUNCTION public.get_prescription_template_details(p_id bigint)
 RETURNS json
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_template RECORD;
    v_items JSON;
BEGIN
    -- Lấy Header
    SELECT * INTO v_template FROM public.prescription_templates WHERE id = p_id;
    
    IF v_template IS NULL THEN RETURN NULL; END IF;

    -- Lấy Items (FIX: product_id là BIGINT nên join bình thường)
    SELECT json_agg(json_build_object(
        'id', i.id,
        'product_id', i.product_id,
        'product_name', p.name,
        'product_unit', p.retail_unit, -- Giả sử bảng products có cột retail_unit
        'quantity', i.quantity,
        'usage_instruction', i.usage_instruction
    ))
    INTO v_items
    FROM public.prescription_template_items i
    JOIN public.products p ON i.product_id = p.id
    WHERE i.template_id = p_id;

    RETURN json_build_object(
        'template', row_to_json(v_template),
        'items', COALESCE(v_items, '[]'::json)
    );
END;
$function$
