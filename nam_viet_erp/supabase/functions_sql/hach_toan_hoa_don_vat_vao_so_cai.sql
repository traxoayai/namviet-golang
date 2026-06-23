CREATE OR REPLACE FUNCTION public.hach_toan_hoa_don_vat_vao_so_cai(p_invoice_id bigint)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_invoice record;
    v_journal_id bigint;
    v_period_id bigint;
    v_acc_156 uuid;
    v_acc_1331 uuid;
    v_acc_331 uuid;
    v_total_pre_tax numeric;
    v_tax_amount numeric;
    v_total_post_tax numeric;
BEGIN
    -- Lấy thông tin hóa đơn
    SELECT * INTO v_invoice 
    FROM finance_invoices 
    WHERE id = p_invoice_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Hóa đơn không tồn tại (ID: %)', p_invoice_id;
    END IF;

    -- Kiểm tra trùng lặp
    IF EXISTS (SELECT 1 FROM journal_entries WHERE source_ref_type = 'INVOICE' AND source_ref_id = p_invoice_id::text) THEN
        RAISE EXCEPTION 'Hóa đơn này đã được hạch toán vào Sổ cái!';
    END IF;

    -- Xác định kỳ kế toán hiện tại (đơn giản hóa: kỳ đang mở)
    -- (Trong thực tế cần query bảng accounting_periods. Tạm thời set 0 nếu chưa có bảng).
    v_period_id := 0;

    -- Lấy mã Tài khoản từ bảng chart_of_accounts
    SELECT id INTO v_acc_156 FROM chart_of_accounts WHERE account_code = '1561' LIMIT 1;
    IF v_acc_156 IS NULL THEN
        SELECT id INTO v_acc_156 FROM chart_of_accounts WHERE account_code = '156' LIMIT 1;
    END IF;
    
    SELECT id INTO v_acc_1331 FROM chart_of_accounts WHERE account_code = '1331' LIMIT 1;
    SELECT id INTO v_acc_331 FROM chart_of_accounts WHERE account_code = '331' LIMIT 1;

    IF v_acc_156 IS NULL OR v_acc_331 IS NULL THEN
        RAISE EXCEPTION 'Chưa khai báo danh mục tài khoản (156 hoặc 331)! Hãy kiểm tra lại chart_of_accounts.';
    END IF;

    v_total_pre_tax := COALESCE(v_invoice.total_amount_pre_tax, 0);
    v_tax_amount := COALESCE(v_invoice.tax_amount, 0);
    v_total_post_tax := COALESCE(v_invoice.total_amount_post_tax, 0);

    IF v_total_post_tax = 0 THEN
      -- Cố gắng tính lại nếu dữ liệu lưu bị thiếu
      v_total_post_tax := v_total_pre_tax + v_tax_amount;
    END IF;

    -- Tạo Sổ cái chung (journal_entries) - Mặc định Sổ BOTH
    INSERT INTO journal_entries (book, entry_date, period_id, doc_type, source_ref_type, source_ref_id, description, status, total_debit, total_credit, created_by)
    VALUES (
        'BOTH', 
        COALESCE(v_invoice.invoice_date, CURRENT_DATE), 
        v_period_id, 
        'MUA_HANG', 
        'INVOICE', 
        p_invoice_id::text, 
        'Hạch toán hóa đơn mua hàng ' || COALESCE(v_invoice.invoice_number, ''), 
        'posted', 
        v_total_post_tax, 
        v_total_post_tax, 
        v_invoice.created_by
    ) RETURNING id INTO v_journal_id;

    -- Nợ 156
    IF v_total_pre_tax > 0 THEN
      INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
      VALUES (v_journal_id, v_acc_156, v_total_pre_tax, 0, v_invoice.supplier_id::text, 'Giá trị hàng hóa', 1);
    END IF;

    -- Nợ 1331
    IF v_tax_amount > 0 AND v_acc_1331 IS NOT NULL THEN
      INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
      VALUES (v_journal_id, v_acc_1331, v_tax_amount, 0, v_invoice.supplier_id::text, 'Thuế GTGT đầu vào', 2);
    END IF;

    -- Có 331
    IF v_total_post_tax > 0 THEN
      INSERT INTO journal_entry_lines (entry_id, account_id, debit, credit, partner_id, description, line_no)
      VALUES (v_journal_id, v_acc_331, 0, v_total_post_tax, v_invoice.supplier_id::text, 'Phải trả nhà cung cấp', 3);
    END IF;

    RETURN TRUE;
END;
$function$
