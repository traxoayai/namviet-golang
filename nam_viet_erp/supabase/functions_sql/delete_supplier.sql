CREATE OR REPLACE FUNCTION public.delete_supplier(p_id bigint)
 RETURNS void
 LANGUAGE sql
AS $function$
    DELETE FROM public.suppliers
    WHERE id = p_id;
$function$
