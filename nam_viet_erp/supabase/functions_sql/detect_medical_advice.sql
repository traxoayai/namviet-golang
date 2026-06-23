CREATE OR REPLACE FUNCTION public.detect_medical_advice(p_content text)
 RETURNS jsonb
 LANGUAGE plpgsql
 IMMUTABLE
AS $function$
DECLARE
  v_matches text[] := ARRAY[]::text[];
  v_severity text := 'low';
  v_kw text;
BEGIN
  IF p_content IS NULL OR length(p_content) = 0 THEN
    RETURN jsonb_build_object('matched', false);
  END IF;

  FOR v_kw IN
    SELECT unnest(ARRAY[
      'liều dùng', 'liều lượng', 'liều cao', 'liều thấp',
      'tác dụng phụ', 'phản ứng phụ',
      'chỉ định', 'chống chỉ định',
      'tương tác thuốc', 'kết hợp với',
      'bà bầu', 'phụ nữ có thai', 'cho con bú',
      'trẻ em', 'trẻ sơ sinh',
      'điều trị', 'chữa khỏi', 'chữa được',
      'dùng bao lâu', 'uống mấy viên', 'mấy lần một ngày',
      'thay thế', 'thay cho'
    ])
  LOOP
    IF position(lower(v_kw) in lower(p_content)) > 0 THEN
      v_matches := array_append(v_matches, v_kw);
    END IF;
  END LOOP;

  -- array_length của empty array trả NULL → bọc COALESCE để branching và
  -- giá trị 'matched' không bị NULL khi không match keyword nào.
  IF COALESCE(array_length(v_matches, 1), 0) >= 3 THEN
    v_severity := 'high';
  ELSIF COALESCE(array_length(v_matches, 1), 0) >= 1 THEN
    v_severity := 'medium';
  END IF;

  RETURN jsonb_build_object(
    'matched', COALESCE(array_length(v_matches, 1), 0) > 0,
    'severity', v_severity,
    'matches', to_jsonb(v_matches)
  );
END;
$function$
