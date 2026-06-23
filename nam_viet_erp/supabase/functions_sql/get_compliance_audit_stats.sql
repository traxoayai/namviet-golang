CREATE OR REPLACE FUNCTION public.get_compliance_audit_stats(p_from date, p_to date)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  WITH gate AS (
    SELECT public.is_chat_staff() AS ok
  ),
  base AS (
    SELECT
      a.id,
      a.severity,
      a.audited_at::date AS day
    FROM public.chat_compliance_audits a, gate
    WHERE gate.ok
      AND a.audited_at::date BETWEEN p_from AND p_to
  ),
  totals AS (
    SELECT
      COUNT(*)::int AS total,
      COUNT(*) FILTER (WHERE severity = 'high')::int   AS sev_high,
      COUNT(*) FILTER (WHERE severity = 'medium')::int AS sev_med,
      COUNT(*) FILTER (WHERE severity = 'low')::int    AS sev_low
    FROM base
  ),
  d AS (
    SELECT generate_series(p_from, p_to, '1 day'::interval)::date AS day
  ),
  per_day AS (
    SELECT b.day, COUNT(*)::int AS cnt
    FROM base b
    GROUP BY b.day
  ),
  series AS (
    SELECT d.day, COALESCE(per_day.cnt, 0)::int AS cnt
    FROM d
    LEFT JOIN per_day USING (day)
    ORDER BY d.day
  )
  SELECT jsonb_build_object(
    'total',  (SELECT total FROM totals),
    'by_severity', jsonb_build_object(
      'high',   (SELECT sev_high FROM totals),
      'medium', (SELECT sev_med  FROM totals),
      'low',    (SELECT sev_low  FROM totals)
    ),
    'by_day', COALESCE(
      (
        SELECT jsonb_agg(jsonb_build_object('day', s.day, 'count', s.cnt) ORDER BY s.day)
        FROM series s
      ),
      '[]'::jsonb
    )
  );
$function$
