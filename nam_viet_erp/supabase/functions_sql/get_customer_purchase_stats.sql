CREATE OR REPLACE FUNCTION public.get_customer_purchase_stats(p_customer_id integer, p_limit integer DEFAULT 20)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN (
    SELECT COALESCE(json_agg(row_data), '[]'::json)
    FROM (
      SELECT oi.product_id, p.name AS product_name, p.sku, p.image_url,
             p.active_ingredient, p.manufacturer_name, p.packing_spec,
             COUNT(DISTINCT o.id) AS order_count,
             SUM(oi.quantity) AS total_quantity_ordered,
             MAX(o.created_at) AS last_ordered_at
      FROM public.order_items oi
      JOIN public.orders o ON o.id = oi.order_id
      JOIN public.products p ON p.id = oi.product_id
      WHERE o.customer_id = p_customer_id AND o.status NOT IN ('CANCELLED', 'DRAFT')
      GROUP BY oi.product_id, p.name, p.sku, p.image_url, p.active_ingredient, p.manufacturer_name, p.packing_spec
      ORDER BY order_count DESC, total_quantity_ordered DESC
      LIMIT p_limit
    ) row_data
  );
END;
$function$
