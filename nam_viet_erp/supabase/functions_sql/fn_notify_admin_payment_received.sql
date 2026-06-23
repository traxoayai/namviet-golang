CREATE OR REPLACE FUNCTION public.fn_notify_admin_payment_received()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_user RECORD;
  v_amount_text TEXT;
  v_partner TEXT;
  v_ref TEXT;
  v_supabase_url TEXT;
  v_service_key TEXT;
BEGIN
  IF NEW.flow != 'in' THEN RETURN NEW; END IF;
  IF NEW.status != 'completed' THEN RETURN NEW; END IF;

  v_amount_text := to_char(NEW.amount, 'FM999,999,999,999') || ' đ';
  v_partner := COALESCE(NEW.partner_name_cache, 'Không rõ');
  v_ref := COALESCE(NEW.ref_id, NEW.code);

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
    WHERE rp.permission_key IN ('portal.manage', 'finance.view_balance', 'admin-all')
  LOOP
    INSERT INTO public.notifications (user_id, title, message, type, category, metadata, reference_id)
    VALUES (
      v_user.user_id,
      'Thanh toán mới: ' || v_amount_text,
      v_partner || ' — ' || v_ref,
      'success',
      'payment_received',
      jsonb_build_object('transaction_id', NEW.id, 'code', NEW.code, 'ref_id', v_ref),
      NULL
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
            'type', 'admin_payment_received',
            'email', v_user.email,
            'data', jsonb_build_object(
              'amount', v_amount_text,
              'partner_name', v_partner,
              'reference', v_ref,
              'description', COALESCE(NEW.description, '')
            )
          ),
          timeout_milliseconds := 3000
        );
      EXCEPTION WHEN OTHERS THEN
        RAISE WARNING '[notify_admin_payment_received] email send failed: %', SQLERRM;
      END;
    END IF;
  END LOOP;

  RETURN NEW;
END;
$function$
