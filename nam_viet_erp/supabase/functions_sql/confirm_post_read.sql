CREATE OR REPLACE FUNCTION public.confirm_post_read(p_post_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    INSERT INTO public.connect_reads (post_id, user_id)
    VALUES (p_post_id, auth.uid())
    ON CONFLICT (post_id, user_id) DO NOTHING; -- Đọc rồi thì thôi không lỗi
END;
$function$
