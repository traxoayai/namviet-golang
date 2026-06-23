CREATE OR REPLACE FUNCTION public.get_products_stock_status(p_product_ids bigint[], p_warehouse_id bigint DEFAULT NULL::bigint)
 RETURNS json
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result JSON;
  v_effective_wh BIGINT;
BEGIN
  -- Default về kho B2B nếu client không truyền
  v_effective_wh := COALESCE(p_warehouse_id, public.get_b2b_warehouse_id());

  SELECT json_agg(json_build_object(
    'product_id', pid,
    'total_quantity', COALESCE(s.total_qty, 0), -- Giữ nguyên base unit để không vỡ B2C
    'wholesale_unit', p.wholesale_unit,
    'wholesale_quantity', FLOOR(COALESCE(s.total_qty, 0) / NULLIF(COALESCE(pu.conversion_rate, 1), 0)), -- Tính sẵn theo đơn vị sỉ cho B2B
    'stock_status', CASE
      WHEN COALESCE(s.total_qty, 0) = 0 THEN 'out_of_stock'
      WHEN COALESCE(s.total_qty, 0) <= (50 * COALESCE(pu.conversion_rate, 1)) THEN 'low_stock'
      ELSE 'in_stock'
    END
  )) INTO v_result
  FROM UNNEST(p_product_ids) pid
  LEFT JOIN public.products p ON p.id = pid
  LEFT JOIN public.product_units pu ON pu.product_id = pid AND pu.unit_name = p.wholesale_unit
  LEFT JOIN (
    SELECT
      ib.product_id,
      SUM(ib.quantity) AS total_qty
    FROM public.inventory_batches ib
    WHERE ib.product_id = ANY(p_product_ids)
      AND ib.warehouse_id = v_effective_wh
    GROUP BY ib.product_id
  ) s ON s.product_id = pid;

  RETURN COALESCE(v_result, '[]'::json);
END;
$function$
