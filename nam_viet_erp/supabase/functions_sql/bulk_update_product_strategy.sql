CREATE OR REPLACE FUNCTION public.bulk_update_product_strategy(p_product_ids bigint[], p_strategy_type text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    UPDATE public.products 
    SET stock_management_type = p_strategy_type::public.stock_management_type, 
        updated_at = now()
    WHERE id = ANY(p_product_ids);
END;
$function$
