CREATE OR REPLACE FUNCTION public.get_po_logistics_stats(p_search text DEFAULT NULL::text, p_status_delivery text DEFAULT NULL::text, p_status_payment text DEFAULT NULL::text, p_date_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_to timestamp with time zone DEFAULT NULL::timestamp with time zone)
 RETURNS TABLE(method text, total_cartons bigint, order_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        RETURN QUERY
        SELECT
            COALESCE(po.delivery_method, 'other') AS method,
            COALESCE(SUM(po.total_packages), 0)::BIGINT AS total_cartons,
            COUNT(po.id)::BIGINT AS order_count
        FROM public.purchase_orders po
        LEFT JOIN public.suppliers s ON po.supplier_id = s.id
        WHERE
            (p_status_delivery IS NULL OR p_status_delivery = '' OR po.delivery_status = p_status_delivery)
            AND (p_status_payment IS NULL OR p_status_payment = '' OR po.payment_status = p_status_payment)
            AND (p_date_from IS NULL OR po.created_at >= p_date_from)
            AND (p_date_to IS NULL OR po.created_at <= p_date_to)
            AND (
                p_search IS NULL OR p_search = ''
                OR po.code ILIKE ('%' || p_search || '%')
                OR s.name ILIKE ('%' || p_search || '%')
            )
        GROUP BY po.delivery_method
        ORDER BY total_cartons DESC;
    END;
    $function$
