CREATE OR REPLACE FUNCTION public.get_b2b_orders_view(p_page integer DEFAULT 1, p_page_size integer DEFAULT 10, p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_date_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_uid uuid := auth.uid();
        v_offset int := (p_page - 1) * p_page_size;
        v_result JSONB;
        v_stats JSONB;
    BEGIN
        SELECT jsonb_build_object(
            'sales_this_month', COALESCE(SUM(o.final_amount) FILTER (WHERE o.created_at >= date_trunc('month', now())), 0),
            'draft_count', COUNT(*) FILTER (WHERE o.status IN ('DRAFT', 'QUOTE')),
            'pending_payment', COUNT(*) FILTER (WHERE o.paid_amount < o.final_amount AND o.status NOT IN ('DRAFT', 'CANCELLED'))
        ) INTO v_stats
        FROM public.orders o
        JOIN public.customers_b2b c ON o.customer_id = c.id
        WHERE (o.creator_id = v_uid OR c.sales_staff_id = v_uid);

        WITH filtered_orders AS (
            SELECT
                o.id,
                o.code,
                c.name as customer_name,
                o.status,
                CASE
                    WHEN o.paid_amount >= o.final_amount THEN 'paid'
                    WHEN o.paid_amount > 0 THEN 'partial'
                    ELSE 'unpaid'
                END as payment_status,
                o.final_amount,
                o.paid_amount,
                o.created_at
            FROM public.orders o
            JOIN public.customers_b2b c ON o.customer_id = c.id
            WHERE
                (o.creator_id = v_uid OR c.sales_staff_id = v_uid)
                AND (p_status IS NULL OR p_status = '' OR o.status = p_status)
                AND (p_date_from IS NULL OR o.created_at >= p_date_from)
                AND (p_date_to IS NULL OR o.created_at <= p_date_to)
                AND (
                    p_search IS NULL OR p_search = ''
                    OR o.code ILIKE '%' || p_search || '%'
                    OR c.name ILIKE '%' || p_search || '%'
                )
        ),
        paginated_orders AS (
            SELECT * FROM filtered_orders
            ORDER BY created_at DESC
            LIMIT p_page_size OFFSET v_offset
        )
        SELECT
            jsonb_build_object(
                'data', COALESCE(jsonb_agg(to_jsonb(t.*)), '[]'::jsonb),
                'total', (SELECT COUNT(*) FROM filtered_orders),
                'stats', v_stats
            ) INTO v_result
        FROM paginated_orders t;

        RETURN COALESCE(v_result, jsonb_build_object('data', '[]'::jsonb, 'total', 0, 'stats', v_stats));
    END;
    $function$
