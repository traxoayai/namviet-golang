CREATE OR REPLACE FUNCTION public.fn_notify_admin_new_portal_order()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user RECORD;
  v_customer_name TEXT;
  v_supabase_url TEXT;
  v_service_key TEXT;
BEGIN
  IF COALESCE(NEW.source, 'erp') <> 'portal' THEN
    RETURN NEW;
  END IF;

  SELECT COALESCE(cb.name, 'Khách hàng')
  INTO v_customer_name
  FROM public.customers_b2b cb
  WHERE cb.id = NEW.customer_id
  LIMIT 1;
  v_customer_name := COALESCE(v_customer_name, 'Khách hàng');

  BEGIN
    SELECT decrypted_secret INTO v_supabase_url FROM vault.decrypted_secrets WHERE name = 'SUPABASE_URL' LIMIT 1;
    SELECT decrypted_secret INTO v_service_key FROM vault.decrypted_secrets WHERE name = 'SUPABASE_SERVICE_ROLE_KEY' LIMIT 1;
  EXCEPTION WHEN OTHERS THEN
    v_supabase_url := NULL;
    v_service_key := NULL;
  END;

  FOR v_user IN
    SELECT DISTINCT ur.user_id, u.email
    FROM public.user_roles ur
    JOIN public.role_permissions rp ON ur.role_id = rp.role_id
    JOIN auth.users u ON ur.user_id = u.id
    WHERE rp.permission_key IN ('portal.manage', 'admin-all')
  LOOP
    INSERT INTO public.notifications (user_id, title, message, type, category, reference_id)
    VALUES (
      v_user.user_id,
      'Đơn hàng Portal mới',
      NEW.code || ' — ' || v_customer_name,
      'info',
      'portal_order',
      NEW.id
    );

    IF v_supabase_url IS NOT NULL AND v_service_key IS NOT NULL AND v_user.email IS NOT NULL THEN
      BEGIN
        PERFORM net.http_post(
          url := v_supabase_url || '/functions/v1/send-portal-email',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || v_service_key
          ),
          body := jsonb_build_object(
            'type', 'admin_new_order',
            'email', v_user.email,
            'data', jsonb_build_object(
              'order_code', NEW.code,
              'customer_name', v_customer_name,
              'total_amount', COALESCE(NEW.final_amount, NEW.total_amount, 0)
            )
          ),
          timeout_milliseconds := 3000
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[notify_admin_new_portal_order] email send failed: %', SQLERRM;
      END;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$
