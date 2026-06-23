CREATE OR REPLACE FUNCTION public.resolve_selling_rule_key(p_product_id bigint)
 RETURNS text
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE pr public.product_regulatory;
BEGIN
  SELECT * INTO pr FROM public.product_regulatory WHERE product_id = p_product_id;
  IF COALESCE(pr.is_vaccine, false) THEN RETURN 'vaccine'; END IF;
  IF pr.special_control_type = 'radioactive' THEN RETURN 'sc_radioactive'; END IF;
  IF pr.special_control_type IN ('narcotic','psychotropic','precursor','toxic') THEN RETURN 'sc_restricted'; END IF;
  IF pr.special_control_type = 'combination' THEN RETURN 'sc_combination'; END IF;
  IF COALESCE(pr.is_restricted_retail, false) THEN RETURN 'restricted_retail'; END IF;
  CASE COALESCE(pr.item_type, 'drug')
    WHEN 'supplement'     THEN RETURN 'supplement';
    WHEN 'medical_device' THEN RETURN 'medical_device';
    WHEN 'herbal'         THEN RETURN 'herbal';
    WHEN 'cosmetic'       THEN RETURN 'cosmetic';
    ELSE NULL;  -- item_type = 'drug' (hoặc thiếu row)
  END CASE;
  IF pr.prescription_class = 'rx'  THEN RETURN 'rx';  END IF;
  IF pr.prescription_class = 'otc' THEN RETURN 'otc'; END IF;
  RETURN 'unclassified';
END;
$function$
