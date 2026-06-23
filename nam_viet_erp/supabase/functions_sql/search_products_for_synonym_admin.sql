CREATE OR REPLACE FUNCTION public.search_products_for_synonym_admin(p_query text, p_limit integer DEFAULT 20)
 RETURNS TABLE(id bigint, name text, sku text, active_ingredient text, synonym_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT
    p.id,
    p.name,
    p.sku,
    p.active_ingredient,
    (SELECT COUNT(*)::int
       FROM public.product_synonyms ps
      WHERE ps.product_id = p.id) AS synonym_count
  FROM public.products p
  WHERE public.is_chat_staff()
    AND p.status = 'active'
    AND length(coalesce(p_query, '')) >= 1
    AND (
      p.name ILIKE '%' || p_query || '%'
      OR p.sku ILIKE '%' || p_query || '%'
    )
  ORDER BY p.name
  LIMIT GREATEST(coalesce(p_limit, 20), 1);
$function$
