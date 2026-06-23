CREATE OR REPLACE FUNCTION public.extract_order_codes_from_memo(p_memo text)
 RETURNS text[]
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public'
AS $function$
DECLARE
  v_normalized text;
  v_remaining text;
  v_result text[] := ARRAY[]::text[];
  v_match text[];
  v_resolved text;
BEGIN
  IF p_memo IS NULL OR btrim(p_memo) = '' THEN
    RETURN ARRAY[]::text[];
  END IF;

  v_normalized := upper(p_memo);

  -- Pattern 1: full code có YYMMDD ở giữa (legacy + user gõ tay full)
  FOR v_match IN
    SELECT regexp_matches(v_normalized, '(SO|POS)[\s-]?(\d{6})[\s-]?(\d{8}|\d{4})', 'g')
  LOOP
    v_result := v_result || (v_match[1] || '-' || v_match[2] || '-' || v_match[3]);
  END LOOP;

  -- Loại bỏ Pattern 1 matches khỏi memo trước khi quét Pattern 2 — tránh
  -- short form bắt lại phần partial của full code (vd `SO260425000068` đầu
  -- của full `SO26042500006840`).
  v_remaining := regexp_replace(
    v_normalized,
    '(SO|POS)[\s-]?\d{6}[\s-]?(\d{8}|\d{4})',
    ' ',
    'g'
  );

  -- Pattern 2: short form `(SO|POS)(\d{8})` — không có YYMMDD.
  -- Resolve qua DB: tìm orders.code KẾT THÚC bằng '-{suffix}'. Sequence
  -- finance_tx_code_seq là global nextval → 8-digit suffix unique trên cả
  -- lifetime đơn → safe để resolve 1-1.
  FOR v_match IN
    SELECT regexp_matches(v_remaining, '(SO|POS)(\d{8})', 'g')
  LOOP
    SELECT code INTO v_resolved
    FROM public.orders
    WHERE code LIKE v_match[1] || '-%-' || v_match[2]
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_resolved IS NOT NULL THEN
      v_result := v_result || v_resolved;
    END IF;
  END LOOP;

  -- Dedupe preserve order
  SELECT COALESCE(ARRAY_AGG(c ORDER BY min_idx), ARRAY[]::text[]) INTO v_result
  FROM (
    SELECT c, MIN(idx) AS min_idx
    FROM unnest(v_result) WITH ORDINALITY AS t(c, idx)
    GROUP BY c
  ) u;

  RETURN v_result;
END;
$function$
