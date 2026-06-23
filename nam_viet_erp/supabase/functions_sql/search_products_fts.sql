CREATE OR REPLACE FUNCTION public.search_products_fts(q text, lim integer DEFAULT 10)
 RETURNS TABLE(id bigint, name text, sku text, stock_status text, score real)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  WITH tsq AS (
    SELECT plainto_tsquery('simple', coalesce(q, '')) AS query
  ),
  matched AS (
    -- Match qua products.fts (name/sku/active_ingredient/barcode)
    SELECT
      p.id,
      p.name,
      p.sku,
      p.stock_status,
      ts_rank(p.fts, tsq.query)::real AS score
    FROM public.products p
    CROSS JOIN tsq
    WHERE p.status = 'active'
      AND p.fts @@ tsq.query

    UNION ALL

    -- Match qua product_synonyms.synonym (xa20, rivaroxaban...)
    SELECT
      p.id,
      p.name,
      p.sku,
      p.stock_status,
      (ts_rank(
        to_tsvector('simple', ps.synonym),
        tsq.query
       ) * ps.weight)::real AS score
    FROM public.product_synonyms ps
    JOIN public.products p ON p.id = ps.product_id
    CROSS JOIN tsq
    WHERE p.status = 'active'
      AND to_tsvector('simple', ps.synonym) @@ tsq.query
  ),
  agg AS (
    SELECT
      m.id,
      max(m.name) AS name,
      max(m.sku) AS sku,
      max(m.stock_status) AS stock_status,
      max(m.score) AS score
    FROM matched m
    GROUP BY m.id
  )
  SELECT a.id, a.name, a.sku, a.stock_status, a.score
  FROM agg a
  WHERE length(coalesce(q, '')) > 0
  ORDER BY a.score DESC, a.id ASC
  LIMIT GREATEST(coalesce(lim, 10), 1);
$function$
