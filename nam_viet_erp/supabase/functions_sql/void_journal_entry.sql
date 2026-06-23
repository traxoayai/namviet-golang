CREATE OR REPLACE FUNCTION public.void_journal_entry(p_entry_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_je RECORD; v_l RECORD;
BEGIN
  PERFORM public.check_rpc_access('void_journal_entry');
  SELECT * INTO v_je FROM public.journal_entries WHERE id=p_entry_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Bút toán #% không tồn tại', p_entry_id; END IF;
  IF (SELECT status FROM public.accounting_periods WHERE id=v_je.period_id)='closed' THEN
    RAISE EXCEPTION 'Kỳ đã khóa, không thể hủy';
  END IF;
  IF v_je.status='posted' THEN
    FOR v_l IN SELECT account_id, debit, credit FROM public.journal_entry_lines WHERE entry_id=p_entry_id LOOP
      UPDATE public.account_balances b
      SET period_debit=b.period_debit-v_l.debit, period_credit=b.period_credit-v_l.credit,
          closing_debit=b.opening_debit+(b.period_debit-v_l.debit),
          closing_credit=b.opening_credit+(b.period_credit-v_l.credit), updated_at=now()
      WHERE b.book=v_je.book AND b.account_id=v_l.account_id AND b.period_id=v_je.period_id;
    END LOOP;
  END IF;
  UPDATE public.journal_entries SET status='void' WHERE id=p_entry_id;
END $function$
