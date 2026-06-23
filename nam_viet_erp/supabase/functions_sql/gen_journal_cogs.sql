CREATE OR REPLACE FUNCTION public.gen_journal_cogs(p_book text, p_source_id text, p_entry_date date, p_cogs numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_lines jsonb;
BEGIN
  PERFORM public.check_rpc_access('gen_journal_cogs');
  IF COALESCE(p_cogs,0) <= 0 THEN RAISE EXCEPTION 'Giá vốn phải > 0'; END IF;
  v_lines := jsonb_build_array(
    jsonb_build_object('account_code','632','debit',p_cogs,'credit',0,'description','Giá vốn'),
    jsonb_build_object('account_code','156','debit',0,'credit',p_cogs,'description','Xuất kho'));
  RETURN public.acc_create_journal_entry(p_book, p_entry_date, 'cogs', 'orders', p_source_id, 'Giá vốn '||p_source_id, v_lines);
END $function$
