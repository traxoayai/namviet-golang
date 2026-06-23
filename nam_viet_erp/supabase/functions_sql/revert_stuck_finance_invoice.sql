CREATE OR REPLACE FUNCTION public.revert_stuck_finance_invoice(p_invoice_id bigint)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
      BEGIN
          UPDATE public.finance_invoices 
          SET status = 'draft' 
          WHERE id = p_invoice_id AND status = 'verified';
      END;
      $function$
