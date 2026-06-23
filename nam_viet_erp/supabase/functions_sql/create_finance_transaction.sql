CREATE OR REPLACE FUNCTION public.create_finance_transaction(p_amount numeric, p_business_type text, p_cash_tally jsonb DEFAULT NULL::jsonb, p_category_id bigint DEFAULT NULL::bigint, p_description text DEFAULT NULL::text, p_flow text DEFAULT 'out'::text, p_fund_id bigint DEFAULT NULL::bigint, p_partner_id text DEFAULT NULL::text, p_partner_name text DEFAULT NULL::text, p_partner_type text DEFAULT NULL::text, p_status text DEFAULT 'pending'::text, p_transaction_date timestamp with time zone DEFAULT now(), p_code text DEFAULT NULL::text, p_ref_type text DEFAULT NULL::text, p_ref_id text DEFAULT NULL::text, p_evidence_url text DEFAULT NULL::text, p_ref_advance_id bigint DEFAULT NULL::bigint, p_created_by uuid DEFAULT NULL::uuid, p_target_bank_info jsonb DEFAULT NULL::jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    DECLARE
        v_new_id BIGINT;
        v_final_code TEXT;
        v_prefix TEXT;
        v_partner_name_final TEXT;
        v_creator_id UUID;
        
        v_flow_enum public.transaction_flow;
        v_biz_enum public.business_type;
        v_status_enum public.transaction_status;

        -- Biến cho logic Hạch toán hóa đơn
        v_invoice record;
        v_diff_amount numeric;
        v_bank_rule_amount numeric := 5000000;
        v_fund_type text;
    BEGIN
        -- A. Chuẩn hóa dữ liệu
        v_flow_enum := p_flow::public.transaction_flow;
        BEGIN v_biz_enum := p_business_type::public.business_type; EXCEPTION WHEN OTHERS THEN v_biz_enum := 'other'; END;
        v_status_enum := COALESCE(p_status, 'pending')::public.transaction_status;
        v_creator_id := COALESCE(p_created_by, auth.uid());

        -- B. Sinh mã phiếu
        IF v_flow_enum = 'in' THEN v_prefix := 'PT'; ELSE v_prefix := 'PC'; END IF;
        IF p_code IS NOT NULL AND p_code <> '' THEN 
            v_final_code := p_code;
        ELSE 
            v_final_code := public._gen_finance_tx_code(v_prefix); 
        END IF;

        -- C. Lấy tên đối tác
        v_partner_name_final := p_partner_name;
        IF v_partner_name_final IS NULL AND p_partner_id IS NOT NULL AND p_partner_id <> '' THEN
            BEGIN
                IF p_partner_type = 'supplier' THEN SELECT name INTO v_partner_name_final FROM public.suppliers WHERE id = p_partner_id::bigint;
                ELSIF p_partner_type = 'customer' THEN SELECT name INTO v_partner_name_final FROM public.customers WHERE id = p_partner_id::bigint;
                ELSIF p_partner_type = 'customer_b2b' THEN SELECT name INTO v_partner_name_final FROM public.customers_b2b WHERE id = p_partner_id::bigint;
                ELSIF p_partner_type = 'employee' THEN SELECT full_name INTO v_partner_name_final FROM public.users WHERE id = p_partner_id::uuid;
                END IF;
            EXCEPTION WHEN OTHERS THEN v_partner_name_final := 'N/A'; END;
        END IF;

        -- D. KIỂM TRA LUẬT HÓA ĐƠN & CHẺ PHIẾU BÙ TRỪ
        IF p_ref_type = 'INVOICE' AND p_ref_id IS NOT NULL AND p_ref_id <> '' THEN
            SELECT * INTO v_invoice FROM finance_invoices WHERE id = p_ref_id::bigint;
            
            IF FOUND THEN
                -- Kiểm tra luật 5 triệu cho hóa đơn VAT
                IF (COALESCE(v_invoice.tax_amount, 0) > 0) AND COALESCE(v_invoice.total_amount_post_tax, 0) >= v_bank_rule_amount THEN
                    -- Lấy type của quỹ
                    SELECT type INTO v_fund_type FROM fund_accounts WHERE id = p_fund_id;
                    IF v_fund_type = 'cash' THEN
                        RAISE EXCEPTION 'Hóa đơn VAT >= 5 triệu bắt buộc phải thanh toán qua Ngân hàng!';
                    END IF;
                END IF;

                -- Tính chênh lệch
                v_diff_amount := p_amount - COALESCE(v_invoice.total_amount_post_tax, 0);

                IF v_diff_amount = 0 THEN
                    -- Thanh toán khớp 100%: Ghi sổ BOTH
                    INSERT INTO public.finance_transactions (
                        code, flow, business_type, category_id, amount, fund_account_id,
                        partner_type, partner_id, partner_name_cache,
                        ref_type, ref_id, description, evidence_url, created_by, status, 
                        transaction_date, ref_advance_id, cash_tally, target_bank_info, book_type, updated_at
                    ) VALUES (
                        v_final_code, v_flow_enum, v_biz_enum, p_category_id, p_amount, p_fund_id,
                        p_partner_type, p_partner_id, v_partner_name_final,
                        p_ref_type, p_ref_id, p_description, p_evidence_url, v_creator_id, v_status_enum, 
                        COALESCE(p_transaction_date, NOW()), p_ref_advance_id, p_cash_tally, p_target_bank_info, 'BOTH', NOW()
                    ) RETURNING id INTO v_new_id;
                ELSE
                    -- CHẺ PHIẾU: Phiếu chính (Sổ BOTH) bằng số tiền hóa đơn
                    INSERT INTO public.finance_transactions (
                        code, flow, business_type, category_id, amount, fund_account_id,
                        partner_type, partner_id, partner_name_cache,
                        ref_type, ref_id, description, evidence_url, created_by, status, 
                        transaction_date, ref_advance_id, cash_tally, target_bank_info, book_type, updated_at
                    ) VALUES (
                        v_final_code, v_flow_enum, v_biz_enum, p_category_id, COALESCE(v_invoice.total_amount_post_tax, 0), p_fund_id,
                        p_partner_type, p_partner_id, v_partner_name_final,
                        p_ref_type, p_ref_id, p_description || ' (Ghi nhận Hóa đơn)', p_evidence_url, v_creator_id, v_status_enum, 
                        COALESCE(p_transaction_date, NOW()), p_ref_advance_id, p_cash_tally, p_target_bank_info, 'BOTH', NOW()
                    ) RETURNING id INTO v_new_id;

                    -- Phiếu bù trừ (Sổ INTERNAL)
                    IF v_diff_amount < 0 THEN
                        -- Trả ít hơn Hóa đơn: Thu bù trừ
                        INSERT INTO public.finance_transactions (
                            code, flow, business_type, category_id, amount, fund_account_id,
                            partner_type, partner_id, partner_name_cache,
                            ref_type, ref_id, description, created_by, status, 
                            transaction_date, book_type, updated_at
                        ) VALUES (
                            public._gen_finance_tx_code('PT'), 'in', 'other', NULL, abs(v_diff_amount), p_fund_id,
                            p_partner_type, p_partner_id, v_partner_name_final,
                            p_ref_type, p_ref_id, 'Thu bù trừ chiết khấu/giảm giá Hóa đơn ' || COALESCE(v_invoice.invoice_number, ''), v_creator_id, 'completed', 
                            COALESCE(p_transaction_date, NOW()), 'INTERNAL', NOW()
                        );
                    ELSE
                        -- Trả nhiều hơn Hóa đơn: Chi bù trừ
                        INSERT INTO public.finance_transactions (
                            code, flow, business_type, category_id, amount, fund_account_id,
                            partner_type, partner_id, partner_name_cache,
                            ref_type, ref_id, description, created_by, status, 
                            transaction_date, book_type, updated_at
                        ) VALUES (
                            public._gen_finance_tx_code('PC'), 'out', 'other', NULL, v_diff_amount, p_fund_id,
                            p_partner_type, p_partner_id, v_partner_name_final,
                            p_ref_type, p_ref_id, 'Chi bù trừ phí/lệ phí thêm Hóa đơn ' || COALESCE(v_invoice.invoice_number, ''), v_creator_id, 'completed', 
                            COALESCE(p_transaction_date, NOW()), 'INTERNAL', NOW()
                        );
                    END IF;
                END IF;

                -- Cập nhật trạng thái Hóa đơn
                UPDATE finance_invoices 
                SET paid_amount = p_amount, 
                    payment_status = CASE 
                        WHEN p_amount >= total_amount_post_tax THEN 'PAID' 
                        WHEN p_amount > 0 THEN 'PARTIAL' 
                        ELSE 'UNPAID' 
                    END
                WHERE id = p_ref_id::bigint;

            ELSE
                -- Nếu truyền ID Hóa đơn sai, fallback về Insert bình thường
                INSERT INTO public.finance_transactions (
                    code, flow, business_type, category_id, amount, fund_account_id,
                    partner_type, partner_id, partner_name_cache,
                    ref_type, ref_id, description, evidence_url, created_by, status, 
                    transaction_date, ref_advance_id, cash_tally, target_bank_info, book_type, updated_at
                ) VALUES (
                    v_final_code, v_flow_enum, v_biz_enum, p_category_id, p_amount, p_fund_id,
                    p_partner_type, p_partner_id, v_partner_name_final,
                    p_ref_type, p_ref_id, p_description, p_evidence_url, v_creator_id, v_status_enum, 
                    COALESCE(p_transaction_date, NOW()), p_ref_advance_id, p_cash_tally, p_target_bank_info, 'INTERNAL', NOW()
                ) RETURNING id INTO v_new_id;
            END IF;
        ELSE
            -- D. Insert Bình thường (Không dính hóa đơn)
            INSERT INTO public.finance_transactions (
                code, flow, business_type, category_id, amount, fund_account_id,
                partner_type, partner_id, partner_name_cache,
                ref_type, ref_id, description, evidence_url, created_by, status, 
                transaction_date, ref_advance_id, cash_tally, target_bank_info, book_type, updated_at
            ) VALUES (
                v_final_code, v_flow_enum, v_biz_enum, p_category_id, p_amount, p_fund_id,
                p_partner_type, p_partner_id, v_partner_name_final,
                p_ref_type, p_ref_id, p_description, p_evidence_url, v_creator_id, v_status_enum, 
                COALESCE(p_transaction_date, NOW()), p_ref_advance_id, p_cash_tally, p_target_bank_info, 'INTERNAL', NOW()
            )
            RETURNING id INTO v_new_id;
        END IF;

        -- E. Hoàn ứng
        IF p_ref_advance_id IS NOT NULL THEN
            UPDATE public.finance_transactions SET status = 'completed', updated_at = now() WHERE id = p_ref_advance_id;
        END IF;

        RETURN v_new_id;
    END;
$function$
