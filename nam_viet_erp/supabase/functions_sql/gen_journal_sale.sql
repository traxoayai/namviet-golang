CREATE OR REPLACE FUNCTION public.gen_journal_sale(p_book text, p_source_id text, p_entry_date date, p_partner text, p_revenue numeric, p_vat numeric)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_lines jsonb; v_total numeric := COALESCE(p_revenue,0)+COALESCE(p_vat,0);
BEGIN
  PERFORM public.check_rpc_access('gen_journal_sale');
  v_lines := jsonb_build_array(
    jsonb_build_object('account_code','131','debit',v_total,'credit',0,'partner_id',p_partner,'description','Phải thu KH'),
    jsonb_build_object('account_code','5111','debit',0,'credit',COALESCE(p_revenue,0),'description','Doanh thu'),
    jsonb_build_object('account_code','33311','debit',0,'credit',COALESCE(p_vat,0),'description','Thuế GTGT đầu ra'));
  IF COALESCE(p_vat,0)=0 THEN v_lines := v_lines - 2; END IF;
  RETURN public.acc_create_journal_entry(p_book, p_entry_date, 'sale', 'orders', p_source_id,
    'Bán hàng '||p_source_id, v_lines);
END $function$
