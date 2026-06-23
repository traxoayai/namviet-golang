CREATE OR REPLACE FUNCTION public.delete_prescription_template(p_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    DELETE FROM public.prescription_template_items WHERE template_id = p_id;
    DELETE FROM public.prescription_templates WHERE id = p_id;
    RETURN TRUE;
END;
$function$
