CREATE OR REPLACE FUNCTION public.delete_vaccination_template(p_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    DELETE FROM public.vaccination_templates WHERE id = p_id;
    RETURN TRUE;
END;
$function$
