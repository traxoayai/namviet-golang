CREATE OR REPLACE FUNCTION public.verify_finance_invoice_atomic(p_invoice_data jsonb, p_items_data jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_invoice_id bigint;
    v_direction text;
    v_status text;
BEGIN
    -- 1. Call upsert to save data
    v_invoice_id := public.upsert_finance_invoice(p_invoice_data, p_items_data);

    -- Get direction and status
    SELECT direction, status INTO v_direction, v_status FROM public.finance_invoices WHERE id = v_invoice_id;

    -- ONLY verify and deduct inventory if status is NOT draft
    IF v_status != 'draft' THEN
        IF v_direction = 'outbound' THEN
            -- Fix status for outbound
            UPDATE public.finance_invoices SET status = 'verified_outbound' WHERE id = v_invoice_id;
            -- Process outbound VAT entry
            PERFORM public.process_vat_export_entry(v_invoice_id);
        ELSE
            -- Process inbound VAT entry
            UPDATE public.finance_invoices SET status = 'verified' WHERE id = v_invoice_id;
            PERFORM public.process_vat_invoice_entry(v_invoice_id);
        END IF;
    END IF;

    RETURN v_invoice_id;
END;
$function$
