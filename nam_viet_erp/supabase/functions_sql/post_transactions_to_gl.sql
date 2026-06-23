CREATE OR REPLACE FUNCTION public.post_transactions_to_gl(p_tx_ids bigint[])
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_tx record;
    v_category record;
    v_fund_gl_account_id text;
    v_category_account_id uuid;
    v_fund_account_id uuid;
    v_debit_account_id uuid;
    v_credit_account_id uuid;
    v_journal_id bigint;
    v_period_id bigint;
    v_books text[];
    v_book text;
    v_success_count int := 0;
BEGIN
    FOR v_tx IN 
        SELECT ft.*, ff.account_id as fund_gl_account_id 
        FROM public.finance_transactions ft
        LEFT JOIN public.fund_accounts ff ON ff.id = ft.fund_account_id
        WHERE ft.id = ANY(p_tx_ids)
    LOOP
        -- Kiểm tra hợp lệ cơ bản
        IF v_tx.status != 'completed' THEN
            RAISE EXCEPTION 'Chỉ có thể hạch toán Phiếu Thu/Chi có trạng thái Hoàn tất. (ID Phiếu: %)', v_tx.id;
        END IF;

        IF v_tx.category_id IS NULL THEN
            RAISE EXCEPTION 'Phiếu Thu/Chi chưa có Lý Do (Category). Vui lòng cập nhật lý do trước khi hạch toán. (ID Phiếu: %)', v_tx.id;
        END IF;

        IF v_tx.fund_gl_account_id IS NULL THEN
            RAISE EXCEPTION 'Quỹ Thu/Chi chưa được gán Tài khoản kế toán. (ID Phiếu: %)', v_tx.id;
        END IF;

        -- Lấy Nợ/Có từ Category
        SELECT * INTO v_category FROM public.transaction_categories WHERE id = v_tx.category_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Không tìm thấy Lý Do Thu/Chi. (ID Phiếu: %)', v_tx.id;
        END IF;

        -- Lấy UUID Nợ/Có từ Category
        SELECT id INTO v_category_account_id FROM public.chart_of_accounts WHERE account_code = v_category.account_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Mã tài khoản (Category) % không tồn tại trong Bảng Hệ Thống Tài Khoản.', v_category.account_id;
        END IF;

        -- Lấy UUID Nợ/Có từ Quỹ
        SELECT id INTO v_fund_account_id FROM public.chart_of_accounts WHERE account_code = v_tx.fund_gl_account_id;
        IF NOT FOUND THEN
            RAISE EXCEPTION 'Mã tài khoản (Quỹ) % không tồn tại trong Bảng Hệ Thống Tài Khoản.', v_tx.fund_gl_account_id;
        END IF;

        -- Xác định Cặp Nợ Có
        IF v_tx.flow = 'in' THEN
            -- Phiếu Thu: Nợ (Tiền) - Có (Lý do)
            v_debit_account_id := v_fund_account_id;
            v_credit_account_id := v_category_account_id;
        ELSE
            -- Phiếu Chi: Nợ (Lý do) - Có (Tiền)
            v_debit_account_id := v_category_account_id;
            v_credit_account_id := v_fund_account_id;
        END IF;

        IF v_debit_account_id IS NULL OR v_credit_account_id IS NULL THEN
            RAISE EXCEPTION 'Tài khoản định khoản không hợp lệ (Lý do Thu/Chi chưa gán TK Nợ/Có). (ID Phiếu: %)', v_tx.id;
        END IF;

        -- Nếu là Tái Hạch Toán: Xóa nhật ký cũ
        IF v_tx.is_posted = true THEN
            DELETE FROM public.journal_entries WHERE source_ref_id = v_tx.id::text AND source_ref_type = 'FINANCE_TRANSACTION';
        END IF;

        -- Xử lý Book type
        IF v_tx.book_type = 'BOTH' THEN
            v_books := ARRAY['INTERNAL', 'TAX'];
        ELSE
            v_books := ARRAY[v_tx.book_type];
        END IF;

        FOREACH v_book IN ARRAY v_books
        LOOP
            -- Check Period (để lưu vào journal entry, lấy INTERNAL làm đại diện nếu BOTH)
            v_period_id := public._get_or_create_accounting_period(v_tx.transaction_date, v_book);

            -- Insert Header
            INSERT INTO public.journal_entries (
                entry_date, book, doc_type, source_ref_type, source_ref_id, description, status, period_id, created_by
            ) VALUES (
                v_tx.transaction_date, v_book, CASE WHEN v_tx.flow = 'in' THEN 'receipt' ELSE 'payment' END, 'FINANCE_TRANSACTION', v_tx.id::text, v_tx.description, 'posted', v_period_id, v_tx.created_by
            ) RETURNING id INTO v_journal_id;

            -- Insert Dòng Nợ
            INSERT INTO public.journal_entry_lines (
                entry_id, account_id, debit, credit, description
            ) VALUES (
                v_journal_id, v_debit_account_id, v_tx.amount, 0, v_tx.description
            );

            -- Insert Dòng Có
            INSERT INTO public.journal_entry_lines (
                entry_id, account_id, debit, credit, description
            ) VALUES (
                v_journal_id, v_credit_account_id, 0, v_tx.amount, v_tx.description
            );
        END LOOP;

        -- Cập nhật cờ
        UPDATE public.finance_transactions SET is_posted = true WHERE id = v_tx.id;
        v_success_count := v_success_count + 1;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'count', v_success_count);
END;
$function$
