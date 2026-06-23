CREATE OR REPLACE FUNCTION public.search_product_batches(p_product_id bigint, p_warehouse_id bigint)
 RETURNS TABLE(id bigint, lot_number text, expiry_date date, quantity integer, days_remaining integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        ib.id, 
        b.batch_code as lot_number, 
        b.expiry_date,
        ib.quantity,
        (b.expiry_date - CURRENT_DATE)::int as days_remaining
    FROM public.inventory_batches ib
    JOIN public.batches b ON ib.batch_id = b.id
    WHERE 
        ib.product_id = p_product_id
        AND ib.warehouse_id = p_warehouse_id
        AND ib.quantity > 0          
        AND b.expiry_date >= CURRENT_DATE 
    ORDER BY b.expiry_date ASC;     
END;
$function$
