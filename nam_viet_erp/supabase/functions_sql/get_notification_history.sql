CREATE OR REPLACE FUNCTION public.get_notification_history(p_customer_b2b_id bigint DEFAULT NULL::bigint, p_type text DEFAULT NULL::text, p_date_from timestamp with time zone DEFAULT NULL::timestamp with time zone, p_date_to timestamp with time zone DEFAULT NULL::timestamp with time zone, p_page integer DEFAULT 1, p_page_size integer DEFAULT 50)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_offset INT;
  v_total  BIGINT;
  v_data   JSON;
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  SELECT COUNT(*) INTO v_total
  FROM public.b2b_notifications n
  WHERE (p_customer_b2b_id IS NULL OR n.customer_b2b_id = p_customer_b2b_id)
    AND (p_type IS NULL OR n.type::text = p_type)
    AND (p_date_from IS NULL OR n.created_at >= p_date_from)
    AND (p_date_to IS NULL OR n.created_at <= p_date_to);

  SELECT json_agg(row_data) INTO v_data
  FROM (
    SELECT
      n.id,
      n.customer_b2b_id,
      c.name AS customer_name,
      c.customer_code,
      n.type,
      n.title,
      n.body,
      n.data,
      n.is_read,
      n.read_at,
      n.created_at
    FROM public.b2b_notifications n
    LEFT JOIN public.customers_b2b c ON c.id = n.customer_b2b_id
    WHERE (p_customer_b2b_id IS NULL OR n.customer_b2b_id = p_customer_b2b_id)
      AND (p_type IS NULL OR n.type::text = p_type)
      AND (p_date_from IS NULL OR n.created_at >= p_date_from)
      AND (p_date_to IS NULL OR n.created_at <= p_date_to)
    ORDER BY n.created_at DESC
    LIMIT p_page_size OFFSET v_offset
  ) row_data;

  RETURN json_build_object(
    'data', COALESCE(v_data, '[]'::json),
    'total', v_total,
    'page', p_page,
    'page_size', p_page_size
  );
END;
$function$
