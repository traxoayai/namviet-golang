CREATE OR REPLACE FUNCTION public.get_cash_flow(p_book text, p_year integer, p_month integer)
 RETURNS TABLE(dong_tien_vao numeric, dong_tien_ra numeric, luu_chuyen_thuan numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_period bigint;
BEGIN
  PERFORM public.check_rpc_access('get_cash_flow');
  SELECT id INTO v_period FROM public.accounting_periods WHERE book=p_book AND year=p_year AND month=p_month;
  RETURN QUERY
  SELECT COALESCE(SUM(b.period_debit),0) AS dong_tien_vao,
         COALESCE(SUM(b.period_credit),0) AS dong_tien_ra,
         COALESCE(SUM(b.period_debit - b.period_credit),0) AS luu_chuyen_thuan
  FROM public.account_balances b
  JOIN public.chart_of_accounts a ON a.id=b.account_id
  WHERE b.book=p_book AND b.period_id=v_period
    AND (a.account_code LIKE '111%' OR a.account_code LIKE '112%');
END $function$
