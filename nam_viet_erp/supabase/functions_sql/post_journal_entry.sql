CREATE OR REPLACE FUNCTION public.post_journal_entry(p_entry_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_entry RECORD;
  v_period RECORD;
  v_line RECORD;
BEGIN
  PERFORM public.check_rpc_access('post_journal_entry');

  -- Fetch entry with joined period check
  SELECT je.*, ap.status as period_status INTO v_entry
  FROM public.journal_entries je
  JOIN public.accounting_periods ap ON ap.id = je.period_id
  WHERE je.id = p_entry_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Journal entry % không tồn tại', p_entry_id;
  END IF;

  -- Check period is open
  IF v_entry.period_status = 'closed' THEN
    RAISE EXCEPTION 'Kỳ % đã khóa, không thể ghi sổ bút toán %', v_entry.period_id, p_entry_id;
  END IF;

  -- Idempotent: if already posted, return success
  IF v_entry.status = 'posted' THEN
    RETURN jsonb_build_object('success', true, 'message', 'Already posted');
  END IF;

  -- Validate: must be draft
  IF v_entry.status != 'draft' THEN
    RAISE EXCEPTION 'Bút toán % không phải DRAFT (status=%)', p_entry_id, v_entry.status;
  END IF;

  -- Update entry status → posted
  UPDATE public.journal_entries SET status = 'posted', posted_by = auth.uid(), posted_at = now()
  WHERE id = p_entry_id;

  -- Update account_balances for each line
  FOR v_line IN
    SELECT jel.account_id, jel.debit, jel.credit
    FROM public.journal_entry_lines jel
    WHERE jel.entry_id = p_entry_id
  LOOP
    INSERT INTO public.account_balances (book, account_id, period_id, period_debit, period_credit)
    VALUES (v_entry.book, v_line.account_id, v_entry.period_id, v_line.debit, v_line.credit)
    ON CONFLICT (book, account_id, period_id) DO UPDATE
    SET period_debit = account_balances.period_debit + EXCLUDED.period_debit,
        period_credit = account_balances.period_credit + EXCLUDED.period_credit,
        updated_at = now();
  END LOOP;

  RETURN jsonb_build_object(
    'success', true,
    'entry_id', p_entry_id,
    'entry_status', 'posted',
    'message', 'Entry posted successfully'
  );
END $function$
