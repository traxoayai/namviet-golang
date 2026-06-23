CREATE OR REPLACE FUNCTION public.notify_group(p_permission_key text, p_title text, p_message text, p_type text DEFAULT 'info'::text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_user_id UUID;
    BEGIN
        -- Loop qua danh sách user có quyền này
        FOR v_user_id IN 
            SELECT DISTINCT ur.user_id
            FROM public.user_roles ur
            JOIN public.role_permissions rp ON ur.role_id = rp.role_id
            WHERE rp.permission_key = p_permission_key
        LOOP
            -- Gọi lại hàm cơ sở
            PERFORM public.send_notification(v_user_id, p_title, p_message, p_type);
        END LOOP;
    END;
    $function$
