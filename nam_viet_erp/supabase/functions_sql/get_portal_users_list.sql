CREATE OR REPLACE FUNCTION public.get_portal_users_list(p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text)
 RETURNS TABLE(id uuid, auth_user_id uuid, customer_b2b_id bigint, display_name text, email text, phone text, role text, status text, last_login_at timestamp with time zone, created_at timestamp with time zone, customer_name text, customer_code text, is_banned boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  RETURN QUERY
  SELECT
    pu.id,
    pu.auth_user_id,
    pu.customer_b2b_id,
    pu.display_name,
    pu.email,
    pu.phone,
    pu.role,
    pu.status,
    pu.last_login_at,
    pu.created_at,
    cb.name AS customer_name,
    cb.customer_code,
    COALESCE(au.banned_until > now(), false) AS is_banned
  FROM portal_users pu
  LEFT JOIN customers_b2b cb ON cb.id = pu.customer_b2b_id
  LEFT JOIN auth.users au ON au.id = pu.auth_user_id
  WHERE
    (p_status IS NULL OR pu.status = p_status)
    AND (
      p_search IS NULL
      OR pu.display_name ILIKE '%' || p_search || '%'
      OR pu.email ILIKE '%' || p_search || '%'
      OR cb.name ILIKE '%' || p_search || '%'
      OR cb.customer_code ILIKE '%' || p_search || '%'
    )
  ORDER BY pu.created_at DESC;
END;
$function$
