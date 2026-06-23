CREATE OR REPLACE FUNCTION public._enforce_same_conv_rate_per_uom()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE v_other NUMERIC;
BEGIN
  SELECT conversion_rate INTO v_other
  FROM public.product_units
  WHERE product_id = NEW.product_id
    AND unit_name = NEW.unit_name
    AND id <> COALESCE(NEW.id, -1)
  LIMIT 1;

  IF v_other IS NOT NULL AND v_other <> NEW.conversion_rate THEN
    RAISE EXCEPTION
      'Đơn vị "%" cho SP % đã có conversion_rate=%; rate mới % sẽ gây ambiguous khi lookup. Dùng tên khác hoặc sync conv.',
      NEW.unit_name, NEW.product_id, v_other, NEW.conversion_rate;
  END IF;

  RETURN NEW;
END;
$function$
