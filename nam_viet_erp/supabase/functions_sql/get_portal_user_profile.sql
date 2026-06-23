CREATE OR REPLACE FUNCTION public.get_portal_user_profile(p_auth_user_id uuid)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result JSON;
BEGIN
  SELECT json_build_object(
    'portal_user', json_build_object(
      'id', pu.id,
      'auth_user_id', pu.auth_user_id,
      'customer_b2b_id', pu.customer_b2b_id,
      'display_name', pu.display_name,
      'email', pu.email,
      'phone', pu.phone,
      'role', pu.role,
      'status', pu.status,
      'last_login_at', pu.last_login_at
    ),
    'customer', json_build_object(
      'id', c.id,
      'customer_code', c.customer_code,
      'name', c.name,
      'phone', c.phone,
      'email', c.email,
      'tax_code', c.tax_code,
      'vat_address', c.vat_address,
      'shipping_address', c.shipping_address,
      'debt_limit', c.debt_limit,
      'current_debt', c.current_debt,
      'payment_term', c.payment_term,
      'ranking', c.ranking,
      'status', c.status
    )
  ) INTO v_result
  FROM public.portal_users pu
  JOIN public.customers_b2b c ON c.id = pu.customer_b2b_id
  WHERE pu.auth_user_id = p_auth_user_id
    AND pu.status = 'active';

  RETURN v_result;
END;
$function$
