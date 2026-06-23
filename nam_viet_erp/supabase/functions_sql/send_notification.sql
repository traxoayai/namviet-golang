CREATE OR REPLACE FUNCTION public.send_notification(p_user_id uuid, p_title text, p_message text, p_type text DEFAULT 'info'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        INSERT INTO public.notifications (user_id, title, message, type, is_read, created_at)
        VALUES (p_user_id, p_title, p_message, p_type, false, now());
    END;
    $function$
