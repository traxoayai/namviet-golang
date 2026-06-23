CREATE OR REPLACE FUNCTION public.can_outlet_sell(p_outlet_type text, p_product_id bigint)
 RETURNS TABLE(allowed boolean, requires_prescription boolean, requires_special_license boolean, rule_key text, reason text)
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  k text;
  r public.selling_rules;
  v_essential boolean;
  v_rx boolean;
BEGIN
  IF p_outlet_type IS NULL THEN
    RETURN QUERY SELECT NULL::boolean, false, false, NULL::text, 'CHUA_XAC_DINH_CO_SO'::text;
    RETURN;
  END IF;
  k := public.resolve_selling_rule_key(p_product_id);
  SELECT COALESCE(pr.is_essential, false), COALESCE(pr.prescription_class = 'rx', false)
    INTO v_essential, v_rx
    FROM public.product_regulatory pr WHERE pr.product_id = p_product_id;
  v_essential := COALESCE(v_essential, false);
  v_rx := COALESCE(v_rx, false);
  SELECT * INTO r FROM public.selling_rules sr WHERE sr.outlet_type = p_outlet_type AND sr.rule_key = k;
  RETURN QUERY SELECT
    (COALESCE(r.is_allowed, false) OR (COALESCE(r.allowed_if_essential, false) AND v_essential)),
    (COALESCE(r.requires_prescription, false) OR v_rx),
    COALESCE(r.requires_special_license, false),
    k,
    CASE WHEN k = 'unclassified' THEN 'CHUA_PHAN_LOAI'::text ELSE NULL::text END;
END;
$function$
