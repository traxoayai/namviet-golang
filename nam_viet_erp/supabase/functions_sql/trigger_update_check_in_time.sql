CREATE OR REPLACE FUNCTION public.trigger_update_check_in_time()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
BEGIN
    -- Nếu trạng thái đổi sang 'waiting' và chưa có giờ check-in -> Gán giờ hiện tại
    IF NEW.status = 'waiting' AND OLD.status != 'waiting' AND NEW.check_in_time IS NULL THEN
        NEW.check_in_time = NOW();
    END IF;
    RETURN NEW;
END;
$function$
