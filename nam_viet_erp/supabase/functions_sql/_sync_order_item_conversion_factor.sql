CREATE OR REPLACE FUNCTION public._sync_order_item_conversion_factor()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_rate NUMERIC;
  v_valid_units TEXT;
BEGIN
  -- UOM rỗng → reject
  IF NEW.uom IS NULL OR btrim(NEW.uom) = '' THEN
    RAISE EXCEPTION 'order_items.uom không được rỗng (product ID=%)', NEW.product_id;
  END IF;

  -- Lookup conversion_rate từ product_units (trim để an toàn với whitespace)
  SELECT conversion_rate INTO v_rate
  FROM public.product_units
  WHERE product_id = NEW.product_id
    AND btrim(unit_name) = btrim(NEW.uom)
  LIMIT 1;

  IF v_rate IS NULL OR v_rate <= 0 THEN
    SELECT string_agg(unit_name, ', ' ORDER BY conversion_rate)
      INTO v_valid_units
    FROM public.product_units
    WHERE product_id = NEW.product_id;

    RAISE EXCEPTION
      'UOM "%" không tồn tại trong product_units cho sản phẩm ID=%. Đơn vị hợp lệ: %.',
      NEW.uom, NEW.product_id, COALESCE(v_valid_units, '(chưa cấu hình)');
  END IF;

  -- Override conversion_factor: DB = single source of truth
  NEW.conversion_factor := v_rate;

  RETURN NEW;
END;
$function$
