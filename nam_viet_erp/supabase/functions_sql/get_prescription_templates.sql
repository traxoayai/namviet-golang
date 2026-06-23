CREATE OR REPLACE FUNCTION public.get_prescription_templates(p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text)
 RETURNS SETOF prescription_templates
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN QUERY
    SELECT *
    FROM public.prescription_templates
    WHERE
        (p_status IS NULL OR p_status = '' OR status = p_status)
        AND
        (p_search IS NULL OR p_search = '' OR name ILIKE '%' || p_search || '%' OR diagnosis ILIKE '%' || p_search || '%')
    ORDER BY created_at DESC;
END;
$function$
