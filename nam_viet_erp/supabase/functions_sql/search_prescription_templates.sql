CREATE OR REPLACE FUNCTION public.search_prescription_templates(p_keyword text DEFAULT ''::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
DECLARE
    v_clean_keyword text := trim(regexp_replace(p_keyword, '\s+', ' ', 'g'));
    v_search_pattern text := '%' || replace(unaccent(v_clean_keyword), ' ', '%') || '%';
    v_result jsonb;
BEGIN
    SELECT COALESCE(jsonb_agg(sub), '[]'::jsonb) INTO v_result
    FROM (
        SELECT 
            t.id, t.name, t.diagnosis, t.note,
            (
                SELECT COALESCE(jsonb_agg(jsonb_build_object(
                    'product_id', p.id, 'product_name', p.name,
                    'unit', COALESCE(p.retail_unit, 'Viên'),
                    'quantity', i.quantity, 'usage_instruction', i.usage_instruction
                )), '[]'::jsonb)
                FROM public.prescription_template_items i
                JOIN public.products p ON i.product_id = p.id
                WHERE i.template_id = t.id
            ) as items
        FROM public.prescription_templates t
        WHERE t.status = 'active'
          AND (v_clean_keyword = '' OR unaccent(t.name) ILIKE v_search_pattern OR unaccent(t.diagnosis) ILIKE v_search_pattern)
        ORDER BY t.created_at DESC
        LIMIT 50
    ) sub;
    RETURN v_result;
END;
$function$
