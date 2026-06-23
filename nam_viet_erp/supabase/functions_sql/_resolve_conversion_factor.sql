CREATE OR REPLACE FUNCTION public._resolve_conversion_factor(p_product_id bigint, p_uom text, p_explicit_factor numeric DEFAULT 0)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_factor NUMERIC;
BEGIN
  IF p_explicit_factor > 0 THEN RETURN p_explicit_factor; END IF;
  SELECT conversion_rate INTO v_factor
  FROM public.product_units
  WHERE product_id = p_product_id AND unit_name = p_uom LIMIT 1;
  RETURN COALESCE(v_factor, 1);
END;
$function$
