CREATE OR REPLACE FUNCTION public.get_customer_order_detail(p_order_id uuid, p_customer_b2b_id bigint)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_order JSON;
  v_items JSON;
BEGIN
  -- Verify ownership
  SELECT json_build_object(
    'id', o.id,
    'code', o.code,
    'status', o.status,
    'payment_status', o.payment_status,
    'payment_method', o.payment_method,
    'total_amount', o.total_amount,
    'final_amount', o.final_amount,
    'shipping_fee', o.shipping_fee,
    'discount_amount', o.discount_amount,
    'delivery_address', o.delivery_address,
    'delivery_method', o.delivery_method,
    'note', o.note,
    'created_at', o.created_at,
    'updated_at', o.updated_at
  ) INTO v_order
  FROM public.orders o
  WHERE o.id = p_order_id
    AND o.customer_id = p_customer_b2b_id;

  IF v_order IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get items
  SELECT json_agg(json_build_object(
    'id', oi.id,
    'product_id', oi.product_id,
    'product_name', p.name,
    'product_sku', p.sku,
    'product_image', p.image_url,
    'quantity', oi.quantity,
    'uom', oi.uom,
    'unit_price', oi.unit_price,
    'discount', oi.discount,
    'total_line', oi.total_line,
    'batch_no', oi.batch_no,
    'expiry_date', oi.expiry_date
  )) INTO v_items
  FROM public.order_items oi
  JOIN public.products p ON p.id = oi.product_id
  WHERE oi.order_id = p_order_id;

  RETURN json_build_object(
    'order', v_order,
    'items', COALESCE(v_items, '[]'::json)
  );
END;
$function$
