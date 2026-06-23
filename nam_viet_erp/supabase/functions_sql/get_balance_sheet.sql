CREATE OR REPLACE FUNCTION public.get_balance_sheet(p_book text, p_year integer, p_month integer)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_period_id bigint;
  v_result jsonb;
  v_total_assets bigint := 0;
  v_total_liabilities bigint := 0;
  v_total_equity bigint := 0;
  v_current_assets jsonb := '[]'::jsonb;
  v_fixed_assets jsonb := '[]'::jsonb;
  v_current_liabilities jsonb := '[]'::jsonb;
  v_long_term_liabilities jsonb := '[]'::jsonb;
  v_equity jsonb := '[]'::jsonb;
  v_account RECORD;
  v_balance_variance bigint;
BEGIN
  PERFORM public.check_rpc_access('get_balance_sheet');

  -- Get period
  SELECT id INTO v_period_id
  FROM public.accounting_periods
  WHERE book = p_book AND year = p_year AND month = p_month;

  -- If period doesn't exist, return structure with zeros
  IF v_period_id IS NULL THEN
    RETURN jsonb_build_object(
      'fiscal_year', p_year,
      'month', p_month,
      'assets', jsonb_build_object('current_assets', '[]'::jsonb, 'fixed_assets', '[]'::jsonb),
      'liabilities', jsonb_build_object('current_liabilities', '[]'::jsonb, 'long_term_liabilities', '[]'::jsonb),
      'equity', '[]'::jsonb,
      'total_assets', 0,
      'total_liabilities', 0,
      'total_equity', 0,
      'is_balanced', true,
      'balance_variance', 0
    );
  END IF;

  -- Fetch current assets (account codes 100-159)
  FOR v_account IN
    SELECT coa.account_code, coa.name,
           COALESCE(ab.closing_debit, 0) - COALESCE(ab.closing_credit, 0) as balance
    FROM public.chart_of_accounts coa
    LEFT JOIN public.account_balances ab ON ab.account_id = coa.id
      AND ab.book = p_book AND ab.period_id = v_period_id
    WHERE SUBSTRING(coa.account_code FROM 1 FOR 3)::int BETWEEN 100 AND 159
    ORDER BY coa.account_code
  LOOP
    IF v_account.balance != 0 THEN
      v_current_assets := v_current_assets || jsonb_build_object(
        'account_code', v_account.account_code,
        'account_name', v_account.name,
        'balance', v_account.balance
      );
      v_total_assets := v_total_assets + v_account.balance;
    END IF;
  END LOOP;

  -- Fetch fixed assets (account codes 160-199)
  FOR v_account IN
    SELECT coa.account_code, coa.name,
           COALESCE(ab.closing_debit, 0) - COALESCE(ab.closing_credit, 0) as balance
    FROM public.chart_of_accounts coa
    LEFT JOIN public.account_balances ab ON ab.account_id = coa.id
      AND ab.book = p_book AND ab.period_id = v_period_id
    WHERE SUBSTRING(coa.account_code FROM 1 FOR 3)::int BETWEEN 160 AND 199
    ORDER BY coa.account_code
  LOOP
    IF v_account.balance != 0 THEN
      v_fixed_assets := v_fixed_assets || jsonb_build_object(
        'account_code', v_account.account_code,
        'account_name', v_account.name,
        'balance', v_account.balance
      );
      v_total_assets := v_total_assets + v_account.balance;
    END IF;
  END LOOP;

  -- Fetch current liabilities (account codes 300-349)
  FOR v_account IN
    SELECT coa.account_code, coa.name,
           COALESCE(ab.closing_credit, 0) - COALESCE(ab.closing_debit, 0) as balance
    FROM public.chart_of_accounts coa
    LEFT JOIN public.account_balances ab ON ab.account_id = coa.id
      AND ab.book = p_book AND ab.period_id = v_period_id
    WHERE SUBSTRING(coa.account_code FROM 1 FOR 3)::int BETWEEN 300 AND 349
    ORDER BY coa.account_code
  LOOP
    IF v_account.balance != 0 THEN
      v_current_liabilities := v_current_liabilities || jsonb_build_object(
        'account_code', v_account.account_code,
        'account_name', v_account.name,
        'balance', v_account.balance
      );
      v_total_liabilities := v_total_liabilities + v_account.balance;
    END IF;
  END LOOP;

  -- Fetch long-term liabilities (account codes 350-399)
  FOR v_account IN
    SELECT coa.account_code, coa.name,
           COALESCE(ab.closing_credit, 0) - COALESCE(ab.closing_debit, 0) as balance
    FROM public.chart_of_accounts coa
    LEFT JOIN public.account_balances ab ON ab.account_id = coa.id
      AND ab.book = p_book AND ab.period_id = v_period_id
    WHERE SUBSTRING(coa.account_code FROM 1 FOR 3)::int BETWEEN 350 AND 399
    ORDER BY coa.account_code
  LOOP
    IF v_account.balance != 0 THEN
      v_long_term_liabilities := v_long_term_liabilities || jsonb_build_object(
        'account_code', v_account.account_code,
        'account_name', v_account.name,
        'balance', v_account.balance
      );
      v_total_liabilities := v_total_liabilities + v_account.balance;
    END IF;
  END LOOP;

  -- Fetch equity (account codes 300-399, credit side, typically 311, 411, 911, 921)
  FOR v_account IN
    SELECT coa.account_code, coa.name,
           COALESCE(ab.closing_credit, 0) - COALESCE(ab.closing_debit, 0) as balance
    FROM public.chart_of_accounts coa
    LEFT JOIN public.account_balances ab ON ab.account_id = coa.id
      AND ab.book = p_book AND ab.period_id = v_period_id
    WHERE coa.account_code ~ '^(311|411|911|921|931)'
    ORDER BY coa.account_code
  LOOP
    IF v_account.balance != 0 THEN
      v_equity := v_equity || jsonb_build_object(
        'account_code', v_account.account_code,
        'account_name', v_account.name,
        'balance', v_account.balance
      );
      v_total_equity := v_total_equity + v_account.balance;
    END IF;
  END LOOP;

  -- Validate balance equation
  v_balance_variance := v_total_assets - (v_total_liabilities + v_total_equity);

  v_result := jsonb_build_object(
    'fiscal_year', p_year,
    'month', p_month,
    'statement_date', make_date(p_year, p_month, 1),
    'assets', jsonb_build_object(
      'current_assets', v_current_assets,
      'fixed_assets', v_fixed_assets
    ),
    'liabilities', jsonb_build_object(
      'current_liabilities', v_current_liabilities,
      'long_term_liabilities', v_long_term_liabilities
    ),
    'equity', v_equity,
    'total_assets', v_total_assets,
    'total_liabilities', v_total_liabilities,
    'total_equity', v_total_equity,
    'is_balanced', ABS(v_balance_variance) < 1000,
    'balance_variance', v_balance_variance
  );

  RETURN v_result;
END $function$
