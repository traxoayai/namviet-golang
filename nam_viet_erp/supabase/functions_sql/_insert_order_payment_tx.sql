CREATE OR REPLACE FUNCTION public._insert_order_payment_tx(p_order_id uuid, p_amount numeric, p_description text, p_bank_ref text DEFAULT NULL::text, p_status text DEFAULT 'completed'::text)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_order RECORD;
  v_partner RECORD;
  v_fund_id BIGINT;
  v_trans_code TEXT;
BEGIN
  SELECT id, code INTO v_order FROM public.orders WHERE id = p_order_id;
  IF v_order.id IS NULL THEN
    RAISE EXCEPTION 'Order % không tồn tại', p_order_id;
  END IF;

  SELECT * INTO v_partner FROM public._resolve_order_partner(p_order_id);

  SELECT id INTO v_fund_id
  FROM public.fund_accounts WHERE type = 'bank' LIMIT 1;
  IF v_fund_id IS NULL THEN v_fund_id := 1; END IF;

  v_trans_code := public._gen_finance_tx_code('PT');

  INSERT INTO public.finance_transactions (
    code, amount, flow, business_type, fund_account_id,
    partner_type, partner_id, partner_name_cache,
    ref_type, ref_id, description, status, bank_reference_id
  ) VALUES (
    v_trans_code, p_amount, 'in', 'trade', v_fund_id,
    v_partner.partner_type, v_partner.partner_id, v_partner.partner_name,
    'order', v_order.code,
    p_description, p_status, p_bank_ref
  );

  RETURN v_trans_code;
END;
$function$
