CREATE OR REPLACE FUNCTION public.list_inbox_sessions(p_tab text, p_limit integer DEFAULT 50)
 RETURNS TABLE(id uuid, user_id uuid, status text, assigned_sales_id uuid, draft_cart_id uuid, platform text, context jsonb, started_at timestamp with time zone, last_activity_at timestamp with time zone, closed_at timestamp with time zone, customer_name text, customer_phone text, unresolved_handoff_reason text, last_message_preview text, last_message_at timestamp with time zone)
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_status text;
  v_limit integer;
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền truy cập inbox' USING ERRCODE = '42501';
  END IF;

  v_status := CASE p_tab
    WHEN 'pending' THEN 'handoff_pending'
    WHEN 'active'  THEN 'human'
    WHEN 'closed'  THEN 'closed'
    ELSE NULL
  END;

  IF v_status IS NULL THEN
    RAISE EXCEPTION 'p_tab phải là pending | active | closed' USING ERRCODE = '22023';
  END IF;

  v_limit := COALESCE(p_limit, 50);
  IF v_limit <= 0 OR v_limit > 500 THEN
    v_limit := 50;
  END IF;

  RETURN QUERY
  SELECT
    s.id,
    s.user_id,
    s.status,
    s.assigned_sales_id,
    s.draft_cart_id,
    s.platform,
    s.context,
    s.started_at,
    s.last_activity_at,
    s.closed_at,
    pu.display_name AS customer_name,
    pu.phone        AS customer_phone,
    (
      SELECT h.reason
      FROM public.chat_handoffs h
      WHERE h.session_id = s.id
        AND h.resolved_at IS NULL
      ORDER BY h.created_at DESC
      LIMIT 1
    ) AS unresolved_handoff_reason,
    (
      SELECT m.content
      FROM public.chat_messages m
      WHERE m.session_id = s.id
        AND m.deleted_at IS NULL
      ORDER BY m.created_at DESC
      LIMIT 1
    ) AS last_message_preview,
    COALESCE(
      (
        SELECT m.created_at
        FROM public.chat_messages m
        WHERE m.session_id = s.id
          AND m.deleted_at IS NULL
        ORDER BY m.created_at DESC
        LIMIT 1
      ),
      s.last_activity_at
    ) AS last_message_at
  FROM public.chat_sessions s
  LEFT JOIN public.portal_users pu ON pu.auth_user_id = s.user_id
  WHERE s.status = v_status
  ORDER BY s.last_activity_at DESC
  LIMIT v_limit;
END;
$function$
