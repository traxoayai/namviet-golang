CREATE OR REPLACE FUNCTION public._get_or_create_accounting_period(p_date timestamp with time zone, p_book text)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_year INT := EXTRACT(YEAR FROM p_date);
    v_month INT := EXTRACT(MONTH FROM p_date);
    v_period_id BIGINT;
    v_status TEXT;
BEGIN
    -- Tìm xem có chưa
    SELECT id, status INTO v_period_id, v_status
    FROM public.accounting_periods
    WHERE year = v_year AND month = v_month AND book = p_book;

    -- Nếu có rồi, check trạng thái
    IF FOUND THEN
        IF v_status = 'closed' THEN
            RAISE EXCEPTION 'Kỳ kế toán Tháng %/%, Sổ % đã bị khóa. Không thể hạch toán!', v_month, v_year, p_book;
        END IF;
        RETURN v_period_id;
    END IF;

    -- Nếu chưa có, tạo mới
    INSERT INTO public.accounting_periods (book, year, month, status, opened_at)
    VALUES (p_book, v_year, v_month, 'open', NOW())
    RETURNING id INTO v_period_id;

    RETURN v_period_id;
END;
$function$
