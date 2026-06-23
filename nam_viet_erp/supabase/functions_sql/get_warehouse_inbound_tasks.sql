CREATE OR REPLACE FUNCTION public.get_warehouse_inbound_tasks(p_warehouse_id bigint, p_page integer DEFAULT 1, p_page_size integer DEFAULT 10, p_search text DEFAULT NULL::text, p_status text DEFAULT NULL::text, p_date_from date DEFAULT NULL::date, p_date_to date DEFAULT NULL::date)
 RETURNS TABLE(task_id bigint, code text, supplier_name text, created_at timestamp with time zone, expected_delivery_date timestamp with time zone, expected_delivery_time timestamp with time zone, item_count bigint, progress_percent numeric, status text, total_packages integer, carrier_name text, carrier_contact text, carrier_phone text, total_count bigint)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    DECLARE
        v_offset INTEGER;
    BEGIN
        v_offset := (p_page - 1) * p_page_size;

        RETURN QUERY
        WITH po_metrics AS (
            SELECT 
                poi.po_id,
                COUNT(*) AS _item_count,
                SUM(poi.quantity_ordered) AS _total_ordered,
                SUM(poi.quantity_received) AS _total_received
            FROM public.purchase_order_items poi
            GROUP BY poi.po_id
        ),
        base_query AS (
            SELECT 
                po.id AS _id,
                po.code AS _code,
                s.name AS _supplier_name,
                po.created_at AS _created_at,
                po.expected_delivery_date AS _expected_date,
                po.expected_delivery_time AS _expected_time, -- Real Data
                COALESCE(pm._item_count, 0) AS _item_count,
                
                CASE 
                    WHEN COALESCE(pm._total_ordered, 0) = 0 THEN 0
                    ELSE ROUND((COALESCE(pm._total_received, 0)::NUMERIC / pm._total_ordered) * 100, 1)
                END AS _progress,

                po.delivery_status AS _status,

                -- Logistics Real Data
                COALESCE(po.total_packages, 1) AS _total_packages,
                COALESCE(po.carrier_name, 'Tự vận chuyển') AS _carrier_name,
                COALESCE(po.carrier_contact, '') AS _carrier_contact,
                COALESCE(po.carrier_phone, '') AS _carrier_phone

            FROM public.purchase_orders po
            LEFT JOIN public.suppliers s ON po.supplier_id = s.id
            LEFT JOIN po_metrics pm ON po.id = pm.po_id
            WHERE 
                po.status IN ('PENDING', 'APPROVED', 'COMPLETED', 'PARTIAL') 
                AND (p_status IS NULL OR po.delivery_status = p_status)
                AND (p_date_from IS NULL OR date(po.created_at) >= p_date_from)
                AND (p_date_to IS NULL OR date(po.created_at) <= p_date_to)
                AND (
                    p_search IS NULL OR p_search = '' 
                    OR po.code ILIKE ('%' || p_search || '%')
                    OR s.name ILIKE ('%' || p_search || '%')
                )
        )
        SELECT 
            _id, _code, _supplier_name, _created_at, _expected_date, _expected_time,
            _item_count, _progress, _status,
            _total_packages, _carrier_name, _carrier_contact, _carrier_phone,
            COUNT(*) OVER() AS total_count
        FROM base_query
        ORDER BY 
            (CASE WHEN _status = 'completed' THEN 1 ELSE 0 END) ASC,
            _created_at DESC
        LIMIT p_page_size OFFSET v_offset;
    END;
    $function$
