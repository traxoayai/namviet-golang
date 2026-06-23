CREATE OR REPLACE FUNCTION public.get_service_packages_list(p_search_query text, p_type_filter text, p_status_filter text, p_page_num integer, p_page_size integer)
 RETURNS TABLE(key text, id bigint, name text, sku text, type service_package_type, price numeric, total_cost_price numeric, valid_from date, valid_to date, status account_status, clinical_category text, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  RETURN QUERY
  WITH filtered_data AS (
    SELECT
      s.id,
      s.name,
      s.sku,
      s.type,
      s.price,
      s.total_cost_price,
      s.valid_from,
      s.valid_to,
      s.status,
      s.clinical_category,
      COUNT(*) OVER() AS total_count
    FROM
      public.service_packages s
    WHERE
      (p_type_filter IS NULL OR p_type_filter = '' OR s.type = p_type_filter::public.service_package_type)
    AND
      (p_status_filter IS NULL OR p_status_filter = '' OR s.status = p_status_filter::public.account_status)
    AND
      (p_search_query IS NULL OR p_search_query = '' OR
        s.name ILIKE ('%' || p_search_query || '%') OR
        s.sku ILIKE ('%' || p_search_query || '%')
      )
  )
  SELECT
    fd.id::TEXT AS key,
    fd.*
  FROM
    filtered_data fd
  ORDER BY
    fd.id DESC
  LIMIT p_page_size
  OFFSET (p_page_num - 1) * p_page_size;
END;
$function$
