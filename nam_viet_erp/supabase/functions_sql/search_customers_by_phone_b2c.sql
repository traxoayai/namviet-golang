CREATE OR REPLACE FUNCTION public.search_customers_by_phone_b2c(p_search_query text)
 RETURNS TABLE(key text, id bigint, customer_code text, name text, type customer_b2c_type, phone text, loyalty_points integer, status account_status)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
 RETURN QUERY
 SELECT
 c.id::TEXT AS key,
 c.id,
 c.customer_code,
 c.name,
 c.type,
 c.phone,
 c.loyalty_points,
 c.status
 FROM
 public.customers c
 WHERE
 c.type = 'CaNhan' -- Chỉ tìm cá nhân
 AND
 (
 c.name ILIKE ('%' || p_search_query || '%') OR
 c.phone ILIKE ('%' || p_search_query || '%')
 )
 LIMIT 10; -- Giới hạn 10 kết quả
END;
$function$
