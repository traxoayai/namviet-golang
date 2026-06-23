CREATE OR REPLACE FUNCTION public._resolve_order_partner(p_order_id uuid)
 RETURNS TABLE(partner_type text, partner_id text, partner_name text)
 LANGUAGE sql
 STABLE PARALLEL SAFE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
  SELECT
    CASE
      WHEN o.customer_id IS NOT NULL THEN 'customer_b2b'
      ELSE 'customer'
    END AS partner_type,
    COALESCE(o.customer_id::text, o.customer_b2c_id::text) AS partner_id,
    COALESCE(cb.name, cc.name, 'Khách lẻ') AS partner_name
  FROM public.orders o
  LEFT JOIN public.customers_b2b cb ON cb.id = o.customer_id
  LEFT JOIN public.customers cc ON cc.id = o.customer_b2c_id
  WHERE o.id = p_order_id;
$function$
