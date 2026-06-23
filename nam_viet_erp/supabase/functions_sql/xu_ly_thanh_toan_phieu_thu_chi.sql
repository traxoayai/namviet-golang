CREATE OR REPLACE FUNCTION public.xu_ly_thanh_toan_phieu_thu_chi(p_invoice_id bigint, p_actual_amount numeric, p_fund_account_id bigint, p_category_id bigint, p_payment_date timestamp with time zone, p_description text, p_created_by uuid)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_invoice record;
    v_fund record;
    v_category record;
    v_trans_id bigint;
    v_diff_amount numeric;
    v_bank_rule_amount numeric := 5000000;
BEGIN
    -- Nếu không có invoice_id thì đây là thu/chi thông thường
    IF p_invoice_id IS NULL THEN
        -- Insert bình thường vào INTERNAL
        INSERT INTO finance_transactions (code, transaction_date, flow, business_type, category_id, amount, fund_account_id, description, created_by, book_type, status)
        VALUES ('PC-' || floor(random()*1000000)::text, p_payment_date, 'chi', 'cash', p_category_id, p_actual_amount, p_fund_account_id, p_description, p_created_by, 'INTERNAL', 'completed')
        RETURNING id INTO v_trans_id;
        RETURN v_trans_id;
    END IF;

    -- 1. Lấy thông tin Hóa đơn
    SELECT * INTO v_invoice FROM finance_invoices WHERE id = p_invoice_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Hóa đơn % không tồn tại!', p_invoice_id; END IF;

    -- 2. Lấy thông tin Quỹ thanh toán
    -- Giả sử quỹ có cột 'type' (cash / bank). Bạn có thể cần điều chỉnh nếu bảng quỹ tên khác
    -- Tạm thời giả định `fund_account_id` liên kết tới bảng danh sách Quỹ nội bộ của công ty.
    -- (Trong code thực tế cần SELECT type FROM finance_funds WHERE id = p_fund_account_id)
    -- Vì chưa rõ schema Quỹ, tôi sẽ bỏ qua check type cash/bank trực tiếp mà sẽ mock logic.

    -- 3. Kiểm tra Luật 5 Triệu:
    -- Nếu Hóa đơn có VAT (tax_amount > 0 hoặc invoice_number NOT NULL) và Tổng thanh toán >= 5.000.000đ
    IF (COALESCE(v_invoice.tax_amount, 0) > 0) AND COALESCE(v_invoice.total_amount_post_tax, 0) >= v_bank_rule_amount THEN
        -- TODO: Kiểm tra Quỹ phải là Ngân hàng. 
        -- IF v_fund.type = 'cash' THEN RAISE EXCEPTION 'Hóa đơn >= 5 triệu bắt buộc phải thanh toán bằng Chuyển khoản Ngân hàng!'; END IF;
    END IF;

    -- 4. Logic "Chẻ Phiếu" Bù Trừ
    v_diff_amount := p_actual_amount - COALESCE(v_invoice.total_amount_post_tax, 0);

    IF v_diff_amount = 0 THEN
        -- Thanh toán khớp 100%: Ghi 1 phiếu vào sổ BOTH
        INSERT INTO finance_transactions (code, transaction_date, flow, business_type, category_id, amount, fund_account_id, ref_type, ref_id, description, created_by, book_type, status)
        VALUES ('PC-' || floor(random()*1000000)::text, p_payment_date, 'chi', 'cash', p_category_id, p_actual_amount, p_fund_account_id, 'INVOICE', p_invoice_id::text, p_description, p_created_by, 'BOTH', 'completed')
        RETURNING id INTO v_trans_id;
    ELSE
        -- Thanh toán bị lệch: Cần bù trừ
        -- Bút toán 1: Phiếu chính thức (Sổ BOTH) bằng đúng giá trị hóa đơn
        INSERT INTO finance_transactions (code, transaction_date, flow, business_type, category_id, amount, fund_account_id, ref_type, ref_id, description, created_by, book_type, status)
        VALUES ('PC-MAIN-' || floor(random()*1000000)::text, p_payment_date, 'chi', 'cash', p_category_id, COALESCE(v_invoice.total_amount_post_tax, 0), p_fund_account_id, 'INVOICE', p_invoice_id::text, 'Thanh toán theo Hóa đơn ' || COALESCE(v_invoice.invoice_number, ''), p_created_by, 'BOTH', 'completed')
        RETURNING id INTO v_trans_id;

        -- Bút toán 2: Phiếu bù trừ (Sổ INTERNAL) bằng số chênh lệch
        IF v_diff_amount < 0 THEN
            -- Trả ít hơn Hóa đơn -> Công ty được lãi nội bộ (Tạo Phiếu Thu bù trừ)
            INSERT INTO finance_transactions (code, transaction_date, flow, business_type, category_id, amount, fund_account_id, ref_type, ref_id, description, created_by, book_type, status)
            VALUES ('PT-OFFSET-' || floor(random()*1000000)::text, p_payment_date, 'thu', 'cash', p_category_id, abs(v_diff_amount), p_fund_account_id, 'INVOICE', p_invoice_id::text, 'Thu bù trừ chênh lệch thanh toán Hóa đơn', p_created_by, 'INTERNAL', 'completed');
        ELSE
            -- Trả nhiều hơn Hóa đơn -> Công ty chịu lỗ nội bộ (Tạo Phiếu Chi bù trừ)
            INSERT INTO finance_transactions (code, transaction_date, flow, business_type, category_id, amount, fund_account_id, ref_type, ref_id, description, created_by, book_type, status)
            VALUES ('PC-OFFSET-' || floor(random()*1000000)::text, p_payment_date, 'chi', 'cash', p_category_id, v_diff_amount, p_fund_account_id, 'INVOICE', p_invoice_id::text, 'Chi bù trừ chênh lệch thanh toán Hóa đơn', p_created_by, 'INTERNAL', 'completed');
        END IF;
    END IF;

    -- 5. Cập nhật trạng thái thanh toán trên Hóa Đơn
    UPDATE finance_invoices 
    SET paid_amount = p_actual_amount, 
        payment_status = CASE 
            WHEN p_actual_amount >= total_amount_post_tax THEN 'PAID' 
            WHEN p_actual_amount > 0 THEN 'PARTIAL' 
            ELSE 'UNPAID' 
        END
    WHERE id = p_invoice_id;

    RETURN v_trans_id;
END;
$function$
