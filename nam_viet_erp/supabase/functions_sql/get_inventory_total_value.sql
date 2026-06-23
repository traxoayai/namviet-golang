CREATE OR REPLACE FUNCTION public.get_inventory_total_value(p_warehouse_id bigint DEFAULT NULL::bigint)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT jsonb_build_object(
        'total_value',                COALESCE(SUM(ib.quantity * COALESCE(b.inbound_price, 0)), 0),
        'total_qty',                  COALESCE(SUM(ib.quantity), 0),
        'count_batches',              COUNT(*) FILTER (WHERE ib.quantity > 0),
        'count_zero_price_batches',   COUNT(*) FILTER (WHERE ib.quantity > 0 AND COALESCE(b.inbound_price, 0) = 0)
    )
    FROM public.inventory_batches ib
    JOIN public.batches b ON b.id = ib.batch_id
    WHERE ib.quantity > 0
      AND (p_warehouse_id IS NULL OR ib.warehouse_id = p_warehouse_id);
$function$
