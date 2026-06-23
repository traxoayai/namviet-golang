CREATE OR REPLACE FUNCTION public.toggle_accounting_period_status(p_period_id bigint, p_new_status text)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    IF p_new_status NOT IN ('open', 'closed') THEN
        RAISE EXCEPTION 'Trạng thái không hợp lệ. Chỉ chấp nhận open hoặc closed.';
    END IF;

    UPDATE public.accounting_periods
    SET status = p_new_status,
        closed_at = CASE WHEN p_new_status = 'closed' THEN NOW() ELSE NULL END
    WHERE id = p_period_id;
    
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Không tìm thấy kỳ kế toán với ID = %', p_period_id;
    END IF;
END;
$function$
