CREATE OR REPLACE FUNCTION public.audit_chat_messages_daily(p_for_day date DEFAULT ((now() - '1 day'::interval))::date, p_sample_size integer DEFAULT 50)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_inserted int := 0;
  v_total_scanned int := 0;
BEGIN
  WITH sample AS (
    SELECT m.id, m.session_id, m.content
    FROM public.chat_messages m
    WHERE m.role = 'bot'
      AND m.created_at::date = p_for_day
      AND m.deleted_at IS NULL
      AND m.content IS NOT NULL
    ORDER BY random()
    LIMIT GREATEST(COALESCE(p_sample_size, 50), 1)
  ),
  audited AS (
    SELECT
      s.id AS message_id,
      s.session_id,
      public.detect_medical_advice(s.content) AS result,
      s.content
    FROM sample s
  ),
  ins AS (
    INSERT INTO public.chat_compliance_audits (
      message_id, session_id, rule_code, severity, matched_keywords, excerpt
    )
    SELECT
      a.message_id,
      a.session_id,
      'R-04',
      a.result->>'severity',
      ARRAY(SELECT jsonb_array_elements_text(a.result->'matches')),
      LEFT(a.content, 240)
    FROM audited a
    WHERE (a.result->>'matched')::boolean = true
    ON CONFLICT (message_id, rule_code) DO NOTHING
    RETURNING 1
  ),
  counts AS (
    SELECT
      (SELECT COUNT(*)::int FROM ins) AS inserted_count,
      (SELECT COUNT(*)::int FROM sample) AS sample_count
  )
  SELECT inserted_count, sample_count
    INTO v_inserted, v_total_scanned
  FROM counts;

  RETURN jsonb_build_object(
    'day', p_for_day,
    'scanned', v_total_scanned,
    'flagged', v_inserted
  );
END;
$function$
