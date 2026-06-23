CREATE OR REPLACE FUNCTION public.delete_products(p_ids bigint[])
 RETURNS void
 LANGUAGE sql
AS $function$
    DELETE FROM public.products
    WHERE id = ANY(p_ids);
$function$
