CREATE OR REPLACE FUNCTION public.get_transactions(p_page integer, p_page_size integer, p_search text, p_flow text, p_status text, p_date_from timestamp with time zone, p_date_to timestamp with time zone, p_creator_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id bigint, code text, flow text, amount numeric, status text, partner_name text, transaction_date timestamp with time zone, description text, business_type text, creator_name text, full_count bigint, metadata jsonb)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.code,
        t.flow::TEXT,
        t.amount,
        t.status::TEXT,
        COALESCE(t.partner_name_cache, 'Khách lẻ') as partner_name,
        t.transaction_date,
        t.description,
        t.business_type::TEXT,
        COALESCE(u.full_name, u.email, 'N/A') as creator_name,
        COUNT(*) OVER() as full_count,
        COALESCE(t.target_bank_info, '{}'::jsonb) AS metadata
    FROM public.finance_transactions t
    LEFT JOIN public.users u ON t.created_by = u.id 
    WHERE 
        -- [CORE UPGRADE]: Tìm kiếm đa năng 4 trường
        (
            p_search IS NULL 
            OR t.code ILIKE '%' || p_search || '%'                  -- 1. Tìm theo Mã
            OR t.partner_name_cache ILIKE '%' || p_search || '%'    -- 2. Tìm theo Đối tác
            OR t.description ILIKE '%' || p_search || '%'           -- 3. Tìm theo Nội dung (Mới)
            OR u.full_name ILIKE '%' || p_search || '%'             -- 4. Tìm theo Người tạo (Mới)
            OR u.email ILIKE '%' || p_search || '%'                 -- (Backup) Tìm theo Email người tạo
        )
        
        AND (p_flow IS NULL OR t.flow::TEXT = p_flow)
        AND (p_status IS NULL OR t.status::TEXT = p_status)
        AND (p_date_from IS NULL OR t.transaction_date >= p_date_from)
        AND (p_date_to IS NULL OR t.transaction_date <= p_date_to)
        AND (p_creator_id IS NULL OR t.created_by = p_creator_id) 
    ORDER BY t.transaction_date DESC
    LIMIT p_page_size OFFSET (p_page - 1) * p_page_size;
END;
$function$
