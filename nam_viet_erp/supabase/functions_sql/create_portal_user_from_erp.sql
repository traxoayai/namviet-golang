CREATE OR REPLACE FUNCTION public.create_portal_user_from_erp(p_customer_b2b_id bigint, p_auth_user_id uuid, p_email text, p_display_name text DEFAULT NULL::text, p_phone text DEFAULT NULL::text, p_role text DEFAULT 'owner'::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_portal_user_id uuid;
BEGIN
  -- Validate customer exists
  IF NOT EXISTS (SELECT 1 FROM customers_b2b WHERE id = p_customer_b2b_id AND status = 'active') THEN
    RAISE EXCEPTION 'Khách hàng B2B không tồn tại hoặc đã ngưng hoạt động.';
  END IF;

  -- Check duplicate auth_user_id
  IF EXISTS (SELECT 1 FROM portal_users WHERE auth_user_id = p_auth_user_id) THEN
    RAISE EXCEPTION 'Auth user này đã có portal account.';
  END IF;

  -- Check duplicate email
  IF EXISTS (SELECT 1 FROM portal_users WHERE email = p_email) THEN
    RAISE EXCEPTION 'Email này đã có portal account.';
  END IF;

  INSERT INTO portal_users (
    auth_user_id, customer_b2b_id, display_name, email, phone, role, status
  ) VALUES (
    p_auth_user_id, p_customer_b2b_id,
    COALESCE(p_display_name, p_email),
    p_email, p_phone, p_role, 'active'
  ) RETURNING id INTO v_portal_user_id;

  RETURN v_portal_user_id;
END;
$function$
