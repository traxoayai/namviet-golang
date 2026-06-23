CREATE OR REPLACE FUNCTION public.get_portal_dashboard_stats()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_result JSONB;
  v_today DATE := CURRENT_DATE;
  v_week_start DATE := date_trunc('week', CURRENT_DATE)::DATE;
  v_month_start DATE := date_trunc('month', CURRENT_DATE)::DATE;
BEGIN
  SELECT jsonb_build_object(
    'pending_registrations', (
      SELECT COUNT(*) FROM public.registration_requests WHERE status = 'pending'
    ),
    'orders_today', (
      SELECT COUNT(*) FROM public.orders
      WHERE COALESCE(source, 'erp') = 'portal' AND created_at >= v_today
    ),
    'orders_this_week', (
      SELECT COUNT(*) FROM public.orders
      WHERE COALESCE(source, 'erp') = 'portal' AND created_at >= v_week_start
    ),
    'revenue_this_month', (
      SELECT COALESCE(SUM(final_amount), 0) FROM public.orders
      WHERE COALESCE(source, 'erp') = 'portal'
        AND created_at >= v_month_start
        AND status NOT IN ('DRAFT', 'CANCELLED')
    ),
    'daily_orders', (
      SELECT COALESCE(jsonb_agg(row_to_json(d)), '[]'::jsonb)
      FROM (
        SELECT
          gs::date as date,
          COUNT(o.id) as count
        FROM generate_series(CURRENT_DATE - INTERVAL '29 days', CURRENT_DATE, '1 day') gs
        LEFT JOIN public.orders o
          ON o.created_at::date = gs::date
          AND COALESCE(o.source, 'erp') = 'portal'
        GROUP BY gs::date
        ORDER BY gs::date
      ) d
    )
  ) INTO v_result;

  RETURN v_result;
END;
$function$
