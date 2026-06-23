CREATE OR REPLACE FUNCTION public.get_trial_balance(p_book text, p_year integer, p_month integer)
 RETURNS TABLE(account_code text, account_name text, opening_debit numeric, opening_credit numeric, period_debit numeric, period_credit numeric, closing_debit numeric, closing_credit numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_period_id bigint;
BEGIN
  PERFORM public.check_rpc_access('get_trial_balance');

  -- Lấy period_id theo (book, year, month)
  SELECT id INTO v_period_id
  FROM public.accounting_periods
  WHERE book = p_book AND year = p_year AND month = p_month;

  -- Nếu chưa có kỳ → trả rỗng
  IF v_period_id IS NULL THEN
    RETURN;
  END IF;

  RETURN QUERY
  SELECT
    coa.account_code,
    coa.name          AS account_name,
    ab.opening_debit,
    ab.opening_credit,
    ab.period_debit,
    ab.period_credit,
    ab.closing_debit,
    ab.closing_credit
  FROM public.account_balances ab
  JOIN public.chart_of_accounts coa ON coa.id = ab.account_id
  WHERE ab.book = p_book
    AND ab.period_id = v_period_id
    -- Chỉ lấy dòng có bất kỳ giá trị <> 0
    AND (
      ab.opening_debit  <> 0 OR ab.opening_credit  <> 0 OR
      ab.period_debit   <> 0 OR ab.period_credit   <> 0 OR
      ab.closing_debit  <> 0 OR ab.closing_credit  <> 0
    )
  ORDER BY coa.account_code;
END $function$
