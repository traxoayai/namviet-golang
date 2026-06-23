CREATE OR REPLACE FUNCTION public.get_connect_posts(p_category text, p_search text DEFAULT NULL::text, p_limit integer DEFAULT 50, p_offset integer DEFAULT 0)
 RETURNS TABLE(id bigint, category text, title text, summary text, content text, is_pinned boolean, is_anonymous boolean, priority text, status text, must_confirm boolean, reward_points integer, feedback_response text, created_at timestamp with time zone, creator_id uuid, attachments jsonb[], tags text[], updated_at timestamp with time zone, likes_count bigint, comments_count bigint, creator_name text, creator_avatar text, user_has_liked boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        p.id, p.category, p.title, p.summary, p.content, 
        p.is_pinned, p.is_anonymous, p.priority, p.status,
        p.must_confirm, p.reward_points, p.feedback_response,
        p.created_at, p.creator_id, p.attachments, p.tags, p.updated_at,
        
        -- 1. Đếm Like
        (SELECT COUNT(*) FROM public.connect_likes l WHERE l.post_id = p.id)::BIGINT as likes_count,
        
        -- 2. Đếm Comment
        (SELECT COUNT(*) FROM public.connect_comments c WHERE c.post_id = p.id)::BIGINT as comments_count,

        -- 3. Lấy tên người tạo
        CASE 
            WHEN p.is_anonymous THEN 'Người ẩn danh'
            ELSE COALESCE(u.full_name, u.email, 'Unknown')
        END as creator_name,

        -- 4. Lấy Avatar
        CASE 
            WHEN p.is_anonymous THEN NULL
            ELSE u.avatar_url
        END as creator_avatar,

        -- 5. [QUAN TRỌNG] User hiện tại đã like chưa?
        EXISTS (
            SELECT 1 FROM public.connect_likes cl 
            WHERE cl.post_id = p.id AND cl.user_id = auth.uid()
        ) as user_has_liked

    FROM public.connect_posts p
    LEFT JOIN public.users u ON p.creator_id = u.id
    WHERE 
        p.status = 'published'
        AND (p_category IS NULL OR p_category = 'ALL' OR p.category = p_category)
        AND (
            p_search IS NULL OR TRIM(p_search) = '' 
            OR (p.title ILIKE '%' || TRIM(p_search) || '%' OR p.content ILIKE '%' || TRIM(p_search) || '%')
        )
    ORDER BY p.is_pinned DESC, p.created_at DESC
    LIMIT p_limit OFFSET p_offset;
END;
$function$
