CREATE OR REPLACE FUNCTION public.gen_journal_receipt(p_book text, p_source_id text, p_entry_date date, p_amount numeric, p_category_account text, p_fund_account text, p_partner text, p_desc text)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_lines jsonb;
BEGIN
  PERFORM public.check_rpc_access('gen_journal_receipt');
  IF COALESCE(p_amount,0)<=0 THEN RAISE EXCEPTION 'Số tiền thu phải > 0'; END IF;
  v_lines := jsonb_build_array(
    jsonb_build_object('account_code',p_fund_account,'debit',p_amount,'credit',0,'description','Thu tiền'),
    jsonb_build_object('account_code',p_category_account,'debit',0,'credit',p_amount,'partner_id',p_partner,'description',p_desc));
  RETURN public.acc_create_journal_entry(p_book, p_entry_date, 'receipt', 'finance_transactions', p_source_id, COALESCE(p_desc,'Phiếu thu'), v_lines);
END $function$
