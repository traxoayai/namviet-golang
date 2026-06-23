CREATE OR REPLACE FUNCTION public.audit_is_base_ambiguous()
 RETURNS TABLE(product_id bigint, unit_ids bigint[], unit_names text[], ambiguous_count integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
AS $function$
  -- Products chưa có is_base=true VÀ có nhiều unit conversion_rate=1
  SELECT
    pu.product_id,
    array_agg(pu.id ORDER BY pu.id)          AS unit_ids,
    array_agg(pu.unit_name ORDER BY pu.id)   AS unit_names,
    count(*)::integer                         AS ambiguous_count
  FROM public.product_units pu
  WHERE pu.conversion_rate = 1
    AND pu.product_id IN (
      -- products không có is_base=true
      SELECT product_id
      FROM public.product_units
      GROUP BY product_id
      HAVING COUNT(*) FILTER (WHERE is_base = true) = 0
    )
  GROUP BY pu.product_id
  HAVING COUNT(*) >= 2;
$function$
