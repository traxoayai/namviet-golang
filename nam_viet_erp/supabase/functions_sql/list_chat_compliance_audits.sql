CREATE OR REPLACE FUNCTION public.list_chat_compliance_audits(p_from date, p_to date, p_severity text DEFAULT NULL::text, p_limit integer DEFAULT 100, p_offset integer DEFAULT 0)
 RETURNS TABLE(audit_id uuid, message_id uuid, session_id uuid, rule_code text, severity text, matched_keywords text[], excerpt text, status text, customer_email text, customer_name text, audit_created_at timestamp with time zone)
 LANGUAGE sql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
  SELECT
    a.id                AS audit_id,
    a.message_id        AS message_id,
    a.session_id        AS session_id,
    a.rule_code         AS rule_code,
    a.severity          AS severity,
    a.matched_keywords  AS matched_keywords,
    a.excerpt           AS excerpt,
    a.status            AS status,
    u.email::text       AS customer_email,
    pu.display_name::text AS customer_name,
    a.audited_at        AS audit_created_at
  FROM public.chat_compliance_audits a
  JOIN public.chat_sessions s ON s.id = a.session_id
  LEFT JOIN auth.users      u  ON u.id  = s.user_id
  LEFT JOIN public.portal_users pu ON pu.auth_user_id = s.user_id
  WHERE public.is_chat_staff()
    AND a.audited_at::date BETWEEN p_from AND p_to
    AND (p_severity IS NULL OR a.severity = p_severity)
  ORDER BY a.audited_at DESC
  LIMIT  GREATEST(COALESCE(p_limit, 100), 1)
  OFFSET GREATEST(COALESCE(p_offset, 0), 0);
$function$
