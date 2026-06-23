CREATE OR REPLACE FUNCTION public.get_customers_b2c_list(search_query text, type_filter text, status_filter text, page_num integer, page_size integer, sort_by_debt text DEFAULT NULL::text)
 RETURNS TABLE(key text, id bigint, customer_code text, name text, type customer_b2c_type, phone text, loyalty_points integer, status account_status, avatar_url text, current_debt numeric, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        RETURN QUERY
        WITH debt_calc AS (
            -- Tính công nợ (Chỉ tính các đơn hàng có hiệu lực chưa thanh toán)
            SELECT 
                o.customer_b2c_id,
                SUM(o.final_amount - COALESCE(o.paid_amount, 0)) as debt
            FROM public.orders o
            WHERE o.payment_status != 'paid' 
              AND o.status NOT IN ('DRAFT', 'QUOTE', 'QUOTE_EXPIRED', 'CANCELLED')
            GROUP BY o.customer_b2c_id
        ),
        filtered_customers AS (
            SELECT 
                c.id, 
                c.customer_code, 
                c.name, 
                c.type,
                c.phone, 
                c.loyalty_points, 
                c.status,
                c.avatar_url,
                COALESCE(d.debt, 0) as current_debt
            FROM public.customers c
            LEFT JOIN debt_calc d ON c.id = d.customer_b2c_id
            WHERE 
                (status_filter IS NULL OR c.status = status_filter::public.account_status)
                AND (type_filter IS NULL OR c.type = type_filter::public.customer_b2c_type)
                AND (
                    search_query IS NULL OR search_query = '' OR 
                    
                    -- 1. Tìm theo tên, mã KH
                    c.name ILIKE ('%' || search_query || '%') OR 
                    c.customer_code ILIKE ('%' || search_query || '%') OR
                    
                    -- 2. Tìm SĐT (Cá nhân)
                    c.phone ILIKE ('%' || search_query || '%') OR
                    
                    -- 3. Tìm SĐT (Người liên hệ của Tổ chức) - Nâng cấp
                    c.contact_person_phone ILIKE ('%' || search_query || '%') OR
                    
                    -- 4. [QUAN TRỌNG] Tìm SĐT (Người Giám hộ) - Giữ nguyên logic cũ
                    c.id IN (
                        SELECT cg.customer_id
                        FROM public.customer_guardians cg
                        JOIN public.customers guardian ON cg.guardian_id = guardian.id
                        WHERE guardian.phone ILIKE ('%' || search_query || '%')
                    )
                )
        )
        SELECT 
            fc.id::TEXT as key,
            fc.id,
            fc.customer_code,
            fc.name,
            fc.type,
            fc.phone,
            fc.loyalty_points,
            fc.status,
            fc.avatar_url,
            fc.current_debt,
            (COUNT(*) OVER())::bigint as total_count
        FROM filtered_customers fc
        ORDER BY 
            -- Ưu tiên sắp xếp theo Nợ nếu có yêu cầu
            CASE WHEN sort_by_debt = 'desc' THEN fc.current_debt END DESC NULLS LAST,
            CASE WHEN sort_by_debt = 'asc' THEN fc.current_debt END ASC NULLS LAST,
            -- Mặc định: Mới nhất lên đầu
            fc.id DESC
        LIMIT page_size OFFSET (page_num - 1) * page_size;
    END;
    $function$
