CREATE OR REPLACE FUNCTION public._resolve_conversion_factor_strict(p_product_id bigint, p_uom text, p_explicit_factor numeric DEFAULT 0)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_factor NUMERIC;
  v_valid_units TEXT;
BEGIN
  IF p_uom IS NULL OR btrim(p_uom) = '' THEN
    RAISE EXCEPTION 'Đơn vị tính (uom) không được rỗng cho sản phẩm ID=%.', p_product_id;
  END IF;

  SELECT conversion_rate INTO v_factor
  FROM public.product_units
  WHERE product_id = p_product_id AND btrim(unit_name) = btrim(p_uom)
  LIMIT 1;

  IF v_factor IS NULL OR v_factor <= 0 THEN
    SELECT string_agg(unit_name, ', ' ORDER BY conversion_rate)
      INTO v_valid_units
    FROM public.product_units
    WHERE product_id = p_product_id;

    RAISE EXCEPTION
      'Đơn vị "%" không hợp lệ cho sản phẩm ID=%. Đơn vị hợp lệ: %.',
      p_uom, p_product_id, COALESCE(v_valid_units, '(chưa cấu hình)');
  END IF;

  -- Hint > 0 và khác DB → báo lỗi FE. Trước đây tin hint → bypass bảo vệ.
  IF p_explicit_factor > 0 AND p_explicit_factor <> v_factor THEN
    RAISE EXCEPTION
      'conversion_factor mismatch cho sản phẩm ID=% UOM "%": FE gửi % nhưng DB=%. Lỗi FE — kiểm tra payload.',
      p_product_id, p_uom, p_explicit_factor, v_factor;
  END IF;

  RETURN v_factor;
END;
$function$
