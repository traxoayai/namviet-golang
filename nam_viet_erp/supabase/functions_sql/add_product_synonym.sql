CREATE OR REPLACE FUNCTION public.add_product_synonym(p_product_id bigint, p_synonym text, p_weight real DEFAULT 1.0)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_id bigint;
  v_clean text;
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;

  v_clean := trim(lower(coalesce(p_synonym, '')));
  IF length(v_clean) < 2 THEN
    RAISE EXCEPTION 'Synonym phải >= 2 ký tự' USING ERRCODE = '22023';
  END IF;

  INSERT INTO public.product_synonyms (product_id, synonym, weight)
  VALUES (
    p_product_id,
    v_clean,
    GREATEST(0.1::real, LEAST(coalesce(p_weight, 1.0)::real, 10.0::real))
  )
  ON CONFLICT (product_id, synonym) DO UPDATE
    SET weight = EXCLUDED.weight
  RETURNING id INTO v_id;

  RETURN v_id;
END;
$function$
