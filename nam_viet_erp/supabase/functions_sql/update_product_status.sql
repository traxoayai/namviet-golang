CREATE OR REPLACE FUNCTION public.update_product_status(p_ids bigint[], p_status text)
 RETURNS void
 LANGUAGE sql
AS $function$
    UPDATE public.products
    SET status = p_status, updated_at = now()
    WHERE id = ANY(p_ids);
$function$
