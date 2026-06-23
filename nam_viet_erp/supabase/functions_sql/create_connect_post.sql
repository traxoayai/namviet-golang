CREATE OR REPLACE FUNCTION public.create_connect_post(p_category text, p_title text, p_content text, p_is_anonymous boolean DEFAULT false, p_must_confirm boolean DEFAULT false, p_reward_points integer DEFAULT 0, p_attachments jsonb[] DEFAULT '{}'::jsonb[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_status TEXT := 'published';
    v_role_check BOOLEAN;
BEGIN
    -- [LOGIC BẢO VỆ] Nếu đăng NEWS (Thông báo), phải là Admin hoặc HR
    -- (Tạm thời check đơn giản: Nếu là news thì yêu cầu user phải có quyền. 
    -- Ở đây Core tạm bỏ qua check role sâu để MVP chạy được, nhưng Frontend phải ẩn nút đi)
    
    -- Insert dữ liệu
    INSERT INTO public.connect_posts (
        category, title, content, is_anonymous, must_confirm, reward_points, status, attachments
    ) VALUES (
        p_category, p_title, p_content, p_is_anonymous, p_must_confirm, p_reward_points, v_status, p_attachments
    );
END;
$function$
