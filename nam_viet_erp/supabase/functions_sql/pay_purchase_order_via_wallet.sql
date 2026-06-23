CREATE OR REPLACE FUNCTION public.pay_purchase_order_via_wallet(p_po_id bigint, p_amount numeric)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_po_record RECORD;
    v_wallet_balance NUMERIC;
    v_new_paid NUMERIC;
    v_remaining_po_debt NUMERIC;
    v_supplier_id BIGINT;
    v_supplier_name TEXT;
    v_clearing_fund_id BIGINT;
    v_po_code TEXT;
BEGIN
    -- A. Lấy ID Quỹ Cấn Trừ
    SELECT id INTO v_clearing_fund_id FROM public.fund_accounts WHERE name = 'Cấn trừ công nợ' LIMIT 1;
    -- Fallback nếu không có (hiếm) thì lấy quỹ đầu tiên
    IF v_clearing_fund_id IS NULL THEN SELECT id INTO v_clearing_fund_id FROM public.fund_accounts LIMIT 1; END IF;

    -- B. Validate & Lock PO
    SELECT po.*, s.name as supplier_name 
    INTO v_po_record 
    FROM public.purchase_orders po
    JOIN public.suppliers s ON po.supplier_id = s.id
    WHERE po.id = p_po_id 
    FOR UPDATE;

    IF v_po_record IS NULL THEN 
        RAISE EXCEPTION 'Không tìm thấy đơn mua hàng ID %', p_po_id; 
    END IF;

    v_supplier_id := v_po_record.supplier_id;
    v_supplier_name := v_po_record.supplier_name;
    v_po_code := v_po_record.code;

    -- C. Validate & Lock Wallet
    SELECT balance INTO v_wallet_balance 
    FROM public.supplier_wallets 
    WHERE supplier_id = v_supplier_id 
    FOR UPDATE;

    IF v_wallet_balance IS NULL OR v_wallet_balance < p_amount THEN
        RAISE EXCEPTION 'Số dư Ví NCC không đủ để cấn trừ (Hiện có: %, Cần chi: %)', 
            TO_CHAR(COALESCE(v_wallet_balance, 0), 'FM999,999,999'), 
            TO_CHAR(p_amount, 'FM999,999,999');
    END IF;

    -- D. Validate Amount
    v_remaining_po_debt := v_po_record.final_amount - COALESCE(v_po_record.total_paid, 0);
    
    IF p_amount > (v_remaining_po_debt + 1000) THEN -- Cho phép sai số 1000đ
        RAISE EXCEPTION 'Số tiền cấn trừ (%) lớn hơn số tiền còn nợ của đơn hàng (%)', 
            TO_CHAR(p_amount, 'FM999,999,999'), 
            TO_CHAR(v_remaining_po_debt, 'FM999,999,999');
    END IF;

    -- E. THỰC THI 1: Trừ tiền trong Ví NCC
    UPDATE public.supplier_wallets
    SET balance = balance - p_amount,
        updated_at = NOW()
    WHERE supplier_id = v_supplier_id;

    -- F. THỰC THI 2: Update PO
    v_new_paid := COALESCE(v_po_record.total_paid, 0) + p_amount;
    
    UPDATE public.purchase_orders
    SET total_paid = v_new_paid,
        payment_status = CASE 
            WHEN v_new_paid >= (final_amount - 500) THEN 'paid' 
            ELSE 'partial' 
        END,
        note = COALESCE(note, '') || E'\n[HỆ THỐNG]: Đã cấn trừ Ví NCC: ' || TO_CHAR(p_amount, 'FM999,999,999') || ' đ vào lúc ' || TO_CHAR(NOW(), 'DD/MM/YYYY HH24:MI'),
        updated_at = NOW()
    WHERE id = p_po_id;

    -- G. THỰC THI 3: [CORE ADDED] Tạo giao dịch tài chính để Cân Bằng Báo Cáo
    -- Giao dịch này sẽ ghi nhận là "Đã trả cho NCC", làm giảm công nợ trong báo cáo V33.6
    INSERT INTO public.finance_transactions (
        code,
        partner_type, partner_id, partner_name_cache,
        amount, flow, business_type, status,
        fund_account_id, -- Gắn vào quỹ ảo
        ref_type, ref_id,
        description, created_by, created_at
    ) VALUES (
        'OFFSET-' || TO_CHAR(NOW(), 'YYMMDD') || '-' || floor(random() * 1000)::text,
        'supplier', v_supplier_id::TEXT, v_supplier_name,
        p_amount, 
        'out', -- Chi tiền (giảm nợ)
        'other', -- Hoặc tạo type 'offset' nếu muốn kỹ hơn
        'completed',
        v_clearing_fund_id, -- Quỹ ảo
        'purchase_order', v_po_id::TEXT,
        'Cấn trừ công nợ từ Ví NCC cho đơn ' || v_po_code,
        auth.uid(),
        NOW()
    );

    RETURN jsonb_build_object(
        'success', true, 
        'message', 'Đã cấn trừ thành công.',
        'new_wallet_balance', (v_wallet_balance - p_amount),
        'new_po_paid', v_new_paid
    );
END;
$function$
