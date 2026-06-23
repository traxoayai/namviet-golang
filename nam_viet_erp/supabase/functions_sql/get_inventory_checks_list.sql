CREATE OR REPLACE FUNCTION public.get_inventory_checks_list(p_warehouse_id bigint DEFAULT NULL::bigint, p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_start_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_end_date timestamp with time zone DEFAULT NULL::timestamp with time zone, p_limit integer DEFAULT 20, p_offset integer DEFAULT 0)
 RETURNS TABLE(id bigint, code text, warehouse_name text, status text, created_at timestamp with time zone, completed_at timestamp with time zone, total_system_value numeric, total_actual_value numeric, total_diff_value numeric, created_by_name text, verified_by_name text, note text, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_search_term TEXT;
    BEGIN
        -- Chuẩn hóa từ khóa tìm kiếm
        IF p_search IS NOT NULL AND p_search <> '' THEN
            v_search_term := '%' || p_search || '%';
        ELSE
            v_search_term := NULL;
        END IF;

        RETURN QUERY
        SELECT 
            ic.id,
            ic.code,
            w.name as warehouse_name,
            ic.status,
            ic.created_at,
            ic.completed_at,
            ic.total_system_value,
            ic.total_actual_value,
            ic.total_diff_value,
            
            -- Lấy tên hiển thị (Ưu tiên Fullname, fallback Email)
            COALESCE(u1.full_name, u1.email) as created_by_name,
            COALESCE(u2.full_name, u2.email) as verified_by_name,
            
            ic.note,
            
            -- Đếm tổng số dòng (Window Function - Tối ưu hiệu năng)
            COUNT(*) OVER() as total_count
            
        FROM public.inventory_checks ic
        JOIN public.warehouses w ON ic.warehouse_id = w.id
        LEFT JOIN public.users u1 ON ic.created_by = u1.id
        LEFT JOIN public.users u2 ON ic.verified_by = u2.id
        WHERE 
            -- 1. Lọc theo Kho
            (p_warehouse_id IS NULL OR ic.warehouse_id = p_warehouse_id)
            
            -- 2. Lọc theo Trạng thái
            AND (p_status IS NULL OR ic.status = p_status)
            
            -- 3. Lọc theo Khoảng ngày
            AND (p_start_date IS NULL OR ic.created_at >= p_start_date)
            AND (p_end_date IS NULL OR ic.created_at <= p_end_date)
            
            -- 4. Tìm kiếm nâng cao (Mã, Note, Người tạo, Người kiểm)
            AND (
                v_search_term IS NULL 
                OR ic.code ILIKE v_search_term
                OR ic.note ILIKE v_search_term
                OR u1.full_name ILIKE v_search_term
                OR u1.email ILIKE v_search_term
                OR u2.full_name ILIKE v_search_term
            )
            
        ORDER BY ic.created_at DESC
        LIMIT p_limit OFFSET p_offset;
    END;
    $function$
