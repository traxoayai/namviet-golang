CREATE OR REPLACE FUNCTION public.get_top_products_to_crawl(p_limit integer DEFAULT 1000)
 RETURNS TABLE(id bigint, name text, sku text, barcode text)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  SELECT p.id, p.name, p.sku, p.barcode
  FROM public.products p
  LEFT JOIN (
    SELECT product_id, SUM(quantity) as total_sold
    FROM public.order_items
    GROUP BY product_id
  ) oi ON oi.product_id = p.id
  WHERE p.status = 'active' AND p.description IS NULL
  ORDER BY coalesce(oi.total_sold, 0) DESC, p.id ASC
  LIMIT p_limit;
END;
$function$
