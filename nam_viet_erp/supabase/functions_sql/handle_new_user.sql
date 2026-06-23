CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_is_portal BOOLEAN := COALESCE(
    (NEW.raw_user_meta_data->>'is_portal_user')::boolean,
    false
  );
BEGIN
  -- Portal users không cần row public.users → skip để tránh nested trigger chain
  -- với sync_user_status_to_auth (gây fail "Database error creating new user").
  IF v_is_portal THEN
    RETURN NEW;
  END IF;

  -- ERP employees: giữ nguyên hành vi cũ.
  INSERT INTO public.users (id, email, full_name, avatar_url, status)
  VALUES (
    NEW.id,
    NEW.email,
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'avatar_url',
    'pending_approval'
  );
  RETURN NEW;
END;
$function$
