CREATE OR REPLACE FUNCTION public.get_compliance_audit_detail(p_audit_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_audit       public.chat_compliance_audits;
  v_anchor      public.chat_messages;
  v_before      jsonb;
  v_after       jsonb;
  v_customer    jsonb;
BEGIN
  IF NOT public.is_chat_staff() THEN
    RAISE EXCEPTION 'Không có quyền xem audit chatbot' USING ERRCODE = '42501';
  END IF;

  SELECT * INTO v_audit
  FROM public.chat_compliance_audits
  WHERE id = p_audit_id;

  IF v_audit.id IS NULL THEN
    RETURN jsonb_build_object('not_found', true);
  END IF;

  -- Anchor message bị flag
  SELECT * INTO v_anchor
  FROM public.chat_messages
  WHERE id = v_audit.message_id;

  -- 3 message TRƯỚC anchor trong cùng session (theo created_at DESC, đảo lại)
  SELECT COALESCE(jsonb_agg(row_to_json(m_before) ORDER BY (m_before->>'created_at') ASC), '[]'::jsonb)
  INTO v_before
  FROM (
    SELECT
      m.id,
      m.session_id,
      m.role,
      m.content_type,
      m.content,
      m.created_at
    FROM public.chat_messages m
    WHERE m.session_id = v_audit.session_id
      AND m.deleted_at IS NULL
      AND m.created_at < v_anchor.created_at
    ORDER BY m.created_at DESC
    LIMIT 3
  ) m_before;

  -- 3 message SAU anchor trong cùng session
  SELECT COALESCE(jsonb_agg(row_to_json(m_after) ORDER BY (m_after->>'created_at') ASC), '[]'::jsonb)
  INTO v_after
  FROM (
    SELECT
      m.id,
      m.session_id,
      m.role,
      m.content_type,
      m.content,
      m.created_at
    FROM public.chat_messages m
    WHERE m.session_id = v_audit.session_id
      AND m.deleted_at IS NULL
      AND m.created_at > v_anchor.created_at
    ORDER BY m.created_at ASC
    LIMIT 3
  ) m_after;

  -- Customer info (email + display_name)
  SELECT jsonb_build_object(
    'user_id', s.user_id,
    'email',   u.email,
    'display_name', pu.display_name,
    'platform', s.platform,
    'session_status', s.status
  )
  INTO v_customer
  FROM public.chat_sessions s
  LEFT JOIN auth.users          u  ON u.id  = s.user_id
  LEFT JOIN public.portal_users pu ON pu.auth_user_id = s.user_id
  WHERE s.id = v_audit.session_id;

  RETURN jsonb_build_object(
    'audit',           to_jsonb(v_audit),
    'anchor_message',  to_jsonb(v_anchor),
    'messages_before', COALESCE(v_before, '[]'::jsonb),
    'messages_after',  COALESCE(v_after,  '[]'::jsonb),
    'customer',        COALESCE(v_customer, '{}'::jsonb)
  );
END;
$function$
