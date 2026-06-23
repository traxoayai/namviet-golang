CREATE OR REPLACE FUNCTION public.sync_user_status_to_auth()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        -- Trường hợp 1: User được set là 'active' -> Gỡ Ban (Cho phép đăng nhập)
        IF NEW.status = 'active' THEN
            UPDATE auth.users
            SET banned_until = NULL
            WHERE id = NEW.id;
        
        -- Trường hợp 2: User không phải 'active' (inactive, pending...) -> Ban (Chặn đăng nhập)
        ELSE
            UPDATE auth.users
            SET banned_until = (now() + interval '100 years') -- Ban 100 năm
            WHERE id = NEW.id;
        END IF;

        RETURN NEW;
    END;
    $function$
