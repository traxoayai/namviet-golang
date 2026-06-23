CREATE OR REPLACE FUNCTION public.post_sales_invoice_journal(p_invoice_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_inv RECORD;
    v_entry_id bigint;
    v_period_id bigint;
BEGIN
    SELECT * INTO v_inv FROM sales_invoices WHERE id = p_invoice_id;
    IF v_inv.id IS NULL THEN RAISE EXCEPTION 'Hóa đơn không tồn tại'; END IF;
    IF v_inv.accounting_status = 'posted' THEN RAISE EXCEPTION 'Hóa đơn đã được hạch toán'; END IF;

    -- Lookup period
    SELECT id INTO v_period_id FROM accounting_periods 
    WHERE year = EXTRACT(YEAR FROM v_inv.invoice_date) 
      AND month = EXTRACT(MONTH FROM v_inv.invoice_date) 
      AND status = 'open'
    LIMIT 1;
    
    IF v_period_id IS NULL THEN
        RAISE EXCEPTION 'Kỳ kế toán cho tháng % năm % chưa được mở hoặc không tồn tại', EXTRACT(MONTH FROM v_inv.invoice_date), EXTRACT(YEAR FROM v_inv.invoice_date);
    END IF;

    -- Create Journal Entry
    INSERT INTO journal_entries (book, period_id, entry_date, doc_type, source_ref_type, source_ref_id, description, status, total_debit, total_credit)
    VALUES (
        'INTERNAL', v_period_id, v_inv.invoice_date, 'sale', 'sales_invoices', p_invoice_id::text, 
        'Hạch toán doanh thu bán hàng hóa đơn ' || COALESCE(v_inv.invoice_number, ''),
        'posted', v_inv.final_amount, v_inv.final_amount
    ) RETURNING id INTO v_entry_id;

    -- Debit 131
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '7484e290-9617-45ee-98fb-0c93cbe71b59', v_inv.final_amount, 0, v_inv.buyer_tax_code, 'Phải thu khách hàng', 1);

    -- Credit 511
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '3c7966b3-8b34-4700-a92d-03c5b3f7e93f', 0, v_inv.total_amount_pre_tax, v_inv.buyer_tax_code, 'Doanh thu bán hàng', 2);

    -- Credit 33311
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '519ea13f-5c4e-4f00-bab8-0f900032d258', 0, v_inv.vat_amount, v_inv.buyer_tax_code, 'Thuế GTGT đầu ra', 3);

    -- Update status
    UPDATE sales_invoices SET accounting_status = 'posted' WHERE id = p_invoice_id;
    
    RETURN TRUE;
END;
$function$
