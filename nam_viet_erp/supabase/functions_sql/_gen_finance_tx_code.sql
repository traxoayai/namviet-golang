CREATE OR REPLACE FUNCTION public._gen_finance_tx_code(p_prefix text DEFAULT 'PT'::text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  v_seq bigint;
BEGIN
  v_seq := nextval('public.finance_tx_code_seq');
  RETURN p_prefix || '-' ||
         TO_CHAR(NOW(), 'YYMMDD') || '-' ||
         LPAD((v_seq % 1000000)::text, 6, '0') ||
         LPAD(FLOOR(RANDOM() * 100)::text, 2, '0');
END;
$function$
