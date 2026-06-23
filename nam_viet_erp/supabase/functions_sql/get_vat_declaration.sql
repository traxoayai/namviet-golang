CREATE OR REPLACE FUNCTION public.get_vat_declaration(p_direction text, p_year integer, p_month integer)
 RETURNS TABLE(tax_rate numeric, sum_pre_tax numeric, sum_vat numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
  PERFORM public.check_rpc_access('get_vat_declaration');
  RETURN QUERY
  WITH lines AS (
    SELECT COALESCE((it->>'vat_rate')::numeric,0) AS rate,
           COALESCE((it->>'quantity')::numeric,0) * COALESCE((it->>'unit_price')::numeric,0) AS pre_tax
    FROM public.finance_invoices fi
    CROSS JOIN LATERAL jsonb_array_elements(
      CASE WHEN jsonb_typeof(fi.items_json)='array' THEN fi.items_json ELSE '[]'::jsonb END) AS it
    WHERE fi.direction = p_direction
      AND EXTRACT(YEAR FROM fi.invoice_date) = p_year
      AND EXTRACT(MONTH FROM fi.invoice_date) = p_month
  )
  SELECT l.rate AS tax_rate, SUM(l.pre_tax) AS sum_pre_tax,
         ROUND(SUM(l.pre_tax * l.rate / 100.0),0) AS sum_vat
  FROM lines l GROUP BY l.rate ORDER BY l.rate;
END $function$
