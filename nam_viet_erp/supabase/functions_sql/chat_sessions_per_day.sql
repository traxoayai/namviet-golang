CREATE OR REPLACE FUNCTION public.chat_sessions_per_day(p_from date, p_to date, p_platform text DEFAULT NULL::text)
 RETURNS TABLE(day date, sessions integer, orders integer)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  WITH d AS (
    SELECT generate_series(p_from, p_to, '1 day'::interval)::date AS day
  ),
  s AS (
    SELECT cs.started_at::date AS day,
           COUNT(*)::int       AS cnt
    FROM public.chat_sessions cs
    WHERE public.is_chat_staff()
      AND cs.started_at::date BETWEEN p_from AND p_to
      AND (p_platform IS NULL OR cs.platform = p_platform)
    GROUP BY 1
  ),
  o AS (
    SELECT oo.created_at::date AS day,
           COUNT(*)::int       AS cnt
    FROM public.orders oo
    WHERE public.is_chat_staff()
      AND oo.created_at::date BETWEEN p_from AND p_to
    GROUP BY 1
  )
  SELECT d.day,
         COALESCE(s.cnt, 0)::int AS sessions,
         COALESCE(o.cnt, 0)::int AS orders
  FROM d
  LEFT JOIN s USING (day)
  LEFT JOIN o USING (day)
  ORDER BY d.day;
$function$
