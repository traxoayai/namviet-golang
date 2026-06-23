CREATE OR REPLACE FUNCTION public.get_transfers(p_page integer, p_page_size integer, p_search text, p_status text, p_date_from timestamp with time zone, p_date_to timestamp with time zone, p_creator_id uuid DEFAULT NULL::uuid, p_receiver_id uuid DEFAULT NULL::uuid)
 RETURNS TABLE(id bigint, code text, source_warehouse_name text, dest_warehouse_name text, status text, created_at timestamp with time zone, creator_name text, receiver_name text, note text, full_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    RETURN QUERY
    SELECT 
        t.id,
        t.code,
        w1.name as source_warehouse_name,
        w2.name as dest_warehouse_name,
        t.status,
        t.created_at,
        
        -- Lấy tên người tạo
        COALESCE(u1.full_name, u1.email, 'System') as creator_name,
        
        -- [NEW] Lấy tên người nhận (Nếu chưa có thì hiện ---)
        COALESCE(u2.full_name, u2.email, '---') as receiver_name,
        
        t.note,
        COUNT(*) OVER() as full_count
    FROM public.inventory_transfers t
    JOIN public.warehouses w1 ON t.source_warehouse_id = w1.id
    JOIN public.warehouses w2 ON t.dest_warehouse_id = w2.id
    LEFT JOIN public.users u1 ON t.created_by = u1.id
    LEFT JOIN public.users u2 ON t.received_by = u2.id -- [NEW] Join người nhận
    WHERE 
        -- 1. TÌM KIẾM ĐA NĂNG (Deep Search)
        (p_search IS NULL OR p_search = '' OR 
            -- A. Tìm theo Mã phiếu
            t.code ILIKE '%' || p_search || '%' OR
            
            -- B. Tìm theo Tên người tạo
            COALESCE(u1.full_name, '') ILIKE '%' || p_search || '%' OR
            
            -- C. [NEW] Tìm theo Tên người nhận
            COALESCE(u2.full_name, '') ILIKE '%' || p_search || '%' OR
            
            -- D. Tìm theo Ghi chú
            COALESCE(t.note, '') ILIKE '%' || p_search || '%' OR

            -- E. Tìm theo Sản phẩm bên trong phiếu
            EXISTS (
                SELECT 1 
                FROM public.inventory_transfer_items iti
                JOIN public.products p ON iti.product_id = p.id
                WHERE iti.transfer_id = t.id 
                AND (
                    p.name ILIKE '%' || p_search || '%' 
                    OR p.sku ILIKE '%' || p_search || '%'
                )
            )
        )
        
        -- 2. Các bộ lọc khác
        AND (p_status IS NULL OR t.status = p_status)
        AND (p_date_from IS NULL OR t.created_at >= p_date_from)
        AND (p_date_to IS NULL OR t.created_at <= p_date_to)
        AND (p_creator_id IS NULL OR t.created_by = p_creator_id)
        AND (p_receiver_id IS NULL OR t.received_by = p_receiver_id) -- [NEW] Filter
        
    ORDER BY t.created_at DESC
    LIMIT p_page_size OFFSET (p_page - 1) * p_page_size;
END;
$function$
