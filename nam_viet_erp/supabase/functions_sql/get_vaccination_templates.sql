CREATE OR REPLACE FUNCTION public.get_vaccination_templates(p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text)
 RETURNS TABLE(id bigint, name text, description text, min_age_months integer, max_age_months integer, status text, created_at timestamp with time zone, updated_at timestamp with time zone, item_count bigint)
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT
        t.id,
        t.name,
        t.description,
        t.min_age_months,
        t.max_age_months,
        t.status,
        t.created_at,
        t.updated_at,
        (SELECT COUNT(*) FROM public.vaccination_template_items i WHERE i.template_id = t.id) AS item_count
    FROM public.vaccination_templates t
    WHERE
        (p_status IS NULL OR p_status = '' OR t.status = p_status)
        AND
        (p_search IS NULL OR p_search = '' OR t.name ILIKE '%' || p_search || '%')
    ORDER BY t.created_at DESC;
END;
$function$
