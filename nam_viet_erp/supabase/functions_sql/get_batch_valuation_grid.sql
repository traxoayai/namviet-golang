CREATE OR REPLACE FUNCTION public.get_batch_valuation_grid(p_warehouse_id bigint DEFAULT NULL::bigint, p_search text DEFAULT ''::text, p_only_missing_price boolean DEFAULT false, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(inventory_batch_id bigint, batch_id bigint, product_id bigint, sku text, product_name text, warehouse_id bigint, warehouse_name text, lot_number text, expiry_date date, quantity integer, inbound_price numeric, total_value numeric, last_revalued_at timestamp with time zone, total_count bigint)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    WITH base AS (
        SELECT
            ib.id                         AS inventory_batch_id,
            b.id                          AS batch_id,
            p.id                          AS product_id,
            p.sku                         AS sku,
            p.name                        AS product_name,
            ib.warehouse_id               AS warehouse_id,
            w.name                        AS warehouse_name,
            b.batch_code                  AS lot_number,
            b.expiry_date                 AS expiry_date,
            ib.quantity::integer          AS quantity,
            COALESCE(b.inbound_price, 0)  AS inbound_price,
            (ib.quantity * COALESCE(b.inbound_price, 0))::numeric AS total_value,
            (SELECT MAX(br.created_at) FROM public.batch_revaluations br WHERE br.batch_id = b.id) AS last_revalued_at
        FROM public.inventory_batches ib
        JOIN public.batches  b ON b.id = ib.batch_id
        JOIN public.products p ON p.id = ib.product_id
        LEFT JOIN public.warehouses w ON w.id = ib.warehouse_id
        WHERE ib.quantity > 0
          AND (p_warehouse_id IS NULL OR ib.warehouse_id = p_warehouse_id)
          AND (NOT p_only_missing_price OR COALESCE(b.inbound_price, 0) = 0)
          AND (
                COALESCE(p_search, '') = ''
                OR p.name       ILIKE '%' || p_search || '%'
                OR p.sku        ILIKE '%' || p_search || '%'
                OR b.batch_code ILIKE '%' || p_search || '%'
          )
    )
    SELECT
        base.*,
        (SELECT COUNT(*) FROM base) AS total_count
    FROM base
    ORDER BY base.expiry_date ASC NULLS LAST, base.product_name ASC, base.batch_id ASC
    LIMIT  GREATEST(p_limit, 0)
    OFFSET GREATEST(p_offset, 0);
END;
$function$
