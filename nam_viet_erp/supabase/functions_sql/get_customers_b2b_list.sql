CREATE OR REPLACE FUNCTION public.get_customers_b2b_list(search_query text DEFAULT NULL::text, sales_staff_filter uuid DEFAULT NULL::uuid, status_filter text DEFAULT NULL::text, page_num integer DEFAULT 1, page_size integer DEFAULT 10, sort_by_debt text DEFAULT NULL::text)
 RETURNS TABLE(key text, id bigint, customer_code text, name text, phone text, sales_staff_name text, status account_status, debt_limit numeric, current_debt numeric, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    RETURN QUERY
    WITH debt_calc AS (
        SELECT 
            o.customer_id,
            SUM(o.final_amount - COALESCE(o.paid_amount, 0)) as live_debt
        FROM public.orders o
        WHERE o.customer_id IS NOT NULL
          AND o.status NOT IN ('DRAFT', 'CANCELLED', 'QUOTE', 'QUOTE_EXPIRED')
          AND o.payment_status != 'paid'
        GROUP BY o.customer_id
    ),
    filtered_data AS (
        SELECT 
            c.id::TEXT as key, c.id, c.customer_code, c.name, c.phone,
            COALESCE(u.full_name, 'Chưa phân công') as sales_staff_name,
            c.status, COALESCE(c.debt_limit, 0) as debt_limit,
            COALESCE(d.live_debt, 0) as current_debt
        FROM public.customers_b2b c
        LEFT JOIN public.users u ON c.sales_staff_id = u.id
        LEFT JOIN debt_calc d ON c.id = d.customer_id
        WHERE 
            (search_query IS NULL OR search_query = '' OR 
             c.name ILIKE ('%' || search_query || '%') OR 
             c.phone ILIKE ('%' || search_query || '%') OR
             c.customer_code ILIKE ('%' || search_query || '%'))
            AND (sales_staff_filter IS NULL OR c.sales_staff_id = sales_staff_filter)
            AND (status_filter IS NULL OR c.status = status_filter::public.account_status)
    )
    SELECT fd.*, COUNT(*) OVER()::bigint as total_count
    FROM filtered_data fd
    ORDER BY 
        CASE WHEN sort_by_debt = 'asc' THEN fd.current_debt END ASC NULLS LAST,
        CASE WHEN sort_by_debt = 'desc' THEN fd.current_debt END DESC NULLS LAST,
        fd.id DESC
    LIMIT page_size OFFSET (page_num - 1) * page_size;
END;
$function$
