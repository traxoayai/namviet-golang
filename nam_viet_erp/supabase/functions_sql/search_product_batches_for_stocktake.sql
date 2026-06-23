CREATE OR REPLACE FUNCTION public.search_product_batches_for_stocktake(p_product_id bigint, p_warehouse_id bigint)
 RETURNS TABLE(inventory_batch_id bigint, lot_number text, expiry_date date, quantity integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT
        ib.id AS inventory_batch_id,
        b.batch_code AS lot_number,
        b.expiry_date,
        ib.quantity::integer
    FROM public.inventory_batches ib
    JOIN public.batches b ON ib.batch_id = b.id
    WHERE ib.product_id = p_product_id
      AND ib.warehouse_id = p_warehouse_id
      AND ib.quantity > 0
    ORDER BY b.expiry_date ASC NULLS LAST, b.id ASC;
$function$
