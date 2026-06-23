CREATE OR REPLACE FUNCTION public.bulk_import_synonyms(p_rows jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_row jsonb;
  v_product_id bigint;
  v_sku text;
  v_syn text;
  v_weight real;
  v_inserted int := 0;
  v_skipped int := 0;
  v_errors jsonb := '[]'::jsonb;
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Permission denied' USING ERRCODE = '42501';
  END IF;

  IF p_rows IS NULL OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'p_rows phải là jsonb array' USING ERRCODE = '22023';
  END IF;

  FOR v_row IN SELECT * FROM jsonb_array_elements(p_rows) LOOP
    v_sku := nullif(trim(v_row->>'sku'), '');
    v_syn := nullif(trim(lower(v_row->>'synonym')), '');
    v_weight := GREATEST(
      0.1::real,
      LEAST(coalesce((v_row->>'weight')::real, 1.0::real), 10.0::real)
    );

    IF v_sku IS NULL OR v_syn IS NULL OR length(v_syn) < 2 THEN
      v_errors := v_errors || jsonb_build_object(
        'sku', v_sku,
        'synonym', v_syn,
        'reason', 'sku/synonym rỗng hoặc synonym < 2 ký tự'
      );
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    SELECT p.id INTO v_product_id
    FROM public.products p
    WHERE p.sku = v_sku AND p.status = 'active'
    LIMIT 1;

    IF v_product_id IS NULL THEN
      v_errors := v_errors || jsonb_build_object(
        'sku', v_sku,
        'synonym', v_syn,
        'reason', 'SKU không tồn tại'
      );
      v_skipped := v_skipped + 1;
      CONTINUE;
    END IF;

    BEGIN
      INSERT INTO public.product_synonyms (product_id, synonym, weight)
      VALUES (v_product_id, v_syn, v_weight)
      ON CONFLICT (product_id, synonym) DO UPDATE
        SET weight = EXCLUDED.weight;
      v_inserted := v_inserted + 1;
    EXCEPTION WHEN OTHERS THEN
      v_errors := v_errors || jsonb_build_object(
        'sku', v_sku,
        'synonym', v_syn,
        'reason', SQLERRM
      );
      v_skipped := v_skipped + 1;
    END;
  END LOOP;

  RETURN jsonb_build_object(
    'inserted', v_inserted,
    'skipped', v_skipped,
    'errors', v_errors
  );
END;
$function$
