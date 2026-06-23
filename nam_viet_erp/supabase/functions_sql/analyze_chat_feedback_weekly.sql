CREATE OR REPLACE FUNCTION public.analyze_chat_feedback_weekly(p_week_start date DEFAULT ((now() - '7 days'::interval))::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'pg_catalog'
AS $function$
DECLARE
  v_week_end date := p_week_start + interval '7 days';
  v_feedback_count int := 0;
  v_clusters_inserted int := 0;
  v_top_keywords_limit int := 20;
  v_stopwords text[] := ARRAY[
    'em','anh','chị','tôi','cho','của','là','và','có','không',
    'được','xin','giúp','vui','lòng'
  ];
BEGIN
  -- Đếm feedback trong khoảng tuần để báo cáo
  SELECT COUNT(*)::int INTO v_feedback_count
  FROM public.chat_feedback f
  WHERE f.feedback_type = 'wrong_answer'
    AND f.created_at >= p_week_start
    AND f.created_at <  v_week_end;

  IF v_feedback_count = 0 THEN
    RETURN jsonb_build_object(
      'week_start',         p_week_start,
      'week_end',           v_week_end,
      'feedback_scanned',   0,
      'clusters_inserted',  0,
      'note',               'No wrong_answer feedback in window'
    );
  END IF;

  -- Bước 1: với mỗi feedback wrong_answer, lấy tin user gần nhất TRƯỚC
  --         tin bot bị flag (cùng session, role='user', created_at <= bot's).
  -- Bước 2: tokenize content (lowercase, tách non-word), lọc stopword + length>=4.
  -- Bước 3: aggregate theo keyword → INSERT top N vào clusters.
  WITH feedback_window AS (
    SELECT
      f.id            AS feedback_id,
      f.message_id    AS bot_message_id,
      m.session_id    AS session_id,
      m.created_at    AS bot_created_at
    FROM public.chat_feedback f
    JOIN public.chat_messages m ON m.id = f.message_id
    WHERE f.feedback_type = 'wrong_answer'
      AND f.created_at >= p_week_start
      AND f.created_at <  v_week_end
  ),
  user_prompts AS (
    SELECT DISTINCT ON (fw.feedback_id)
      fw.feedback_id,
      fw.bot_message_id,
      um.id      AS user_message_id,
      um.content AS user_content
    FROM feedback_window fw
    JOIN public.chat_messages um
      ON um.session_id = fw.session_id
     AND um.role = 'user'
     AND um.deleted_at IS NULL
     AND um.created_at <= fw.bot_created_at
     AND um.content IS NOT NULL
    ORDER BY fw.feedback_id, um.created_at DESC
  ),
  tokens AS (
    SELECT
      up.user_message_id,
      lower(trim(t.token)) AS token
    FROM user_prompts up
    CROSS JOIN LATERAL regexp_split_to_table(
      lower(coalesce(up.user_content, '')),
      '[^[:alnum:]]+'
    ) AS t(token)
  ),
  filtered AS (
    SELECT
      t.user_message_id,
      t.token
    FROM tokens t
    WHERE t.token IS NOT NULL
      AND length(t.token) >= 4
      AND NOT (t.token = ANY(v_stopwords))
  ),
  keyword_agg AS (
    SELECT
      f.token                                            AS pattern_keyword,
      COUNT(DISTINCT f.user_message_id)::int             AS feedback_count,
      (ARRAY_AGG(DISTINCT f.user_message_id))[1:5]       AS sample_ids
    FROM filtered f
    GROUP BY f.token
    HAVING COUNT(DISTINCT f.user_message_id) >= 1
    ORDER BY COUNT(DISTINCT f.user_message_id) DESC
    LIMIT v_top_keywords_limit
  ),
  ins AS (
    INSERT INTO public.chat_feedback_weekly_clusters (
      week_start, pattern_keyword, sample_message_ids, feedback_count
    )
    SELECT
      p_week_start,
      ka.pattern_keyword,
      ka.sample_ids,
      ka.feedback_count
    FROM keyword_agg ka
    RETURNING 1
  )
  SELECT COUNT(*)::int INTO v_clusters_inserted FROM ins;

  RETURN jsonb_build_object(
    'week_start',         p_week_start,
    'week_end',           v_week_end,
    'feedback_scanned',   v_feedback_count,
    'clusters_inserted',  v_clusters_inserted
  );
END;
$function$
