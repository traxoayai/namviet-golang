CREATE OR REPLACE FUNCTION public.llm_log_daily_usage(p_day date DEFAULT CURRENT_DATE)
 RETURNS TABLE(provider text, success integer, rate_limit integer, circuit_open integer, tool_use_failed integer, error integer, total_latency_ms bigint)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT
    provider,
    COUNT(*) FILTER (WHERE status = 'success')::int AS success,
    COUNT(*) FILTER (WHERE status = 'rate_limit')::int AS rate_limit,
    COUNT(*) FILTER (WHERE status = 'circuit_open')::int AS circuit_open,
    COUNT(*) FILTER (WHERE status = 'tool_use_failed')::int AS tool_use_failed,
    COUNT(*) FILTER (
      WHERE status NOT IN ('success', 'rate_limit', 'circuit_open', 'tool_use_failed')
    )::int AS error,
    COALESCE(SUM(latency_ms), 0)::bigint AS total_latency_ms
  FROM public.llm_request_log
  WHERE public.is_chat_staff()
    AND created_at::date = p_day
  GROUP BY provider
  ORDER BY provider;
$function$
