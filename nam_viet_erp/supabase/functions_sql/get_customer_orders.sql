CREATE OR REPLACE FUNCTION public.get_customer_orders(p_customer_b2b_id bigint, p_status text DEFAULT NULL::text, p_page integer DEFAULT 1, p_page_size integer DEFAULT 20)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_offset INT;
  v_total BIGINT;
  v_data JSON;
BEGIN
  v_offset := (p_page - 1) * p_page_size;

  SELECT COUNT(*) INTO v_total
  FROM public.orders o
  WHERE o.customer_id = p_customer_b2b_id
    AND (p_status IS NULL OR o.status = p_status);

  SELECT json_agg(row_data) INTO v_data
  FROM (
    SELECT
      o.id,
      o.code,
      o.status,
      o.payment_status,
      o.total_amount,
      o.final_amount,
      o.shipping_fee,
      o.discount_amount,
      o.delivery_address,
      o.delivery_method,
      o.note,
      o.created_at,
      o.updated_at,
      (SELECT COUNT(*) FROM public.order_items oi WHERE oi.order_id = o.id) AS item_count
    FROM public.orders o
    WHERE o.customer_id = p_customer_b2b_id
      AND (p_status IS NULL OR o.status = p_status)
    ORDER BY o.created_at DESC
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
