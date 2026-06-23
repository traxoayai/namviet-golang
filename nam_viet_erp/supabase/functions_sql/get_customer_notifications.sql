CREATE OR REPLACE FUNCTION public.get_customer_notifications(p_customer_b2b_id bigint, p_type text DEFAULT NULL::text, p_unread_only boolean DEFAULT false, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20)
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

  -- Count
  SELECT COUNT(*) INTO v_total
  FROM public.b2b_notifications n
  WHERE (n.customer_b2b_id = p_customer_b2b_id OR n.customer_b2b_id IS NULL)
    AND (p_type IS NULL OR n.type::text = p_type)
    AND (NOT p_unread_only OR n.is_read = false);

  -- Data
  SELECT json_agg(row_data) INTO v_data
  FROM (
    SELECT
      n.id,
      n.customer_b2b_id,
      n.type,
      n.title,
      n.body,
      n.data,
      n.is_read,
      n.read_at,
      n.created_at
    FROM public.b2b_notifications n
    WHERE (n.customer_b2b_id = p_customer_b2b_id OR n.customer_b2b_id IS NULL)
      AND (p_type IS NULL OR n.type::text = p_type)
      AND (NOT p_unread_only OR n.is_read = false)
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
