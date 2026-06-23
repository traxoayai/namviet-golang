CREATE OR REPLACE FUNCTION public.chat_stats_overview(p_from date, p_to date, p_platform text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  WITH sessions_filter AS (
    SELECT s.id,
           s.status,
           s.assigned_sales_id
    FROM public.chat_sessions s
    WHERE public.is_chat_staff()
      AND s.started_at::date BETWEEN p_from AND p_to
      AND (p_platform IS NULL OR s.platform = p_platform)
  ),
  orders_filter AS (
    SELECT o.id
    FROM public.orders o
    WHERE public.is_chat_staff()
      AND o.created_at::date BETWEEN p_from AND p_to
  )
  SELECT jsonb_build_object(
    'total_sessions',  (SELECT COUNT(*)::int FROM sessions_filter),
    'orders_via_bot',  (SELECT COUNT(DISTINCT id)::int FROM orders_filter),
    'handoff_rate',
      (
        SELECT CASE
          WHEN COUNT(*) = 0 THEN 0
          ELSE ROUND(
            100.0 * COUNT(*) FILTER (
              WHERE status IN ('handoff_pending', 'human', 'closed')
                AND assigned_sales_id IS NOT NULL
            ) / COUNT(*),
            1
          )
        END
        FROM sessions_filter
      ),
    'ai_cost_usd', 0,
    'orders_note',
      'orders_via_bot counts all orders in range (orders table has no source/session link).'
  );
$function$
