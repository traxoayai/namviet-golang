CREATE OR REPLACE FUNCTION public.post_purchase_invoice_journal(p_invoice_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_inv RECORD;
    v_entry_id bigint;
    v_period_id bigint;
BEGIN
    SELECT * INTO v_inv FROM finance_invoices WHERE id = p_invoice_id;
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
        'INTERNAL', v_period_id, v_inv.invoice_date, 'purchase', 'finance_invoices', p_invoice_id::text, 
        'Hạch toán mua hàng hóa đơn ' || COALESCE(v_inv.invoice_number, ''),
        'posted', v_inv.total_amount_post_tax, v_inv.total_amount_post_tax
    ) RETURNING id INTO v_entry_id;

    -- Debit 156
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '6840ef05-1fd5-4932-9fb5-ef11b91e9c28', v_inv.total_amount_pre_tax, 0, v_inv.supplier_tax, 'Hàng hóa mua vào', 1);

    -- Debit 1331
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '0af0de01-2218-4876-9fbb-2177f074e3cc', v_inv.tax_amount, 0, v_inv.supplier_tax, 'Thuế GTGT đầu vào', 2);

    -- Credit 331
    INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
    VALUES (v_entry_id, '818a25a3-1101-452a-9fc6-fcb82cc4b133', 0, v_inv.total_amount_post_tax, v_inv.supplier_tax, 'Phải trả người bán', 3);

    -- Update status
    UPDATE finance_invoices SET accounting_status = 'posted' WHERE id = p_invoice_id;
    
    RETURN TRUE;
END;
$function$
