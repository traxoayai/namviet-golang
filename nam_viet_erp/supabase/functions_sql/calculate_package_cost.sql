CREATE OR REPLACE FUNCTION public.calculate_package_cost(p_items jsonb)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_total_cost NUMERIC := 0;
  v_item JSONB;
  v_product_cost NUMERIC;
BEGIN
  -- 1. Loop qua từng item trong mảng JSON
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    -- 2. Lấy giá vốn (actual_cost) của sản phẩm/dịch vụ con từ bảng 'products'
    SELECT COALESCE(p.actual_cost, 0)
    INTO v_product_cost
    FROM public.products p
    WHERE p.id = (v_item->>'item_id')::BIGINT;
    
    -- 3. Cộng dồn vào tổng giá vốn
    v_total_cost := v_total_cost + (v_product_cost * (v_item->>'quantity')::NUMERIC);
  END LOOP;
  
  RETURN v_total_cost;
END;
$function$
