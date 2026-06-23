CREATE OR REPLACE FUNCTION public.confirm_purchase_payment(p_order_id bigint, p_amount numeric, p_fund_account_id bigint, p_payment_method text DEFAULT 'bank_transfer'::text, p_note text DEFAULT NULL::text)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_order RECORD;
    v_supplier_name TEXT;
    v_new_paid numeric;
    v_trans_code text;
    v_status text;
    v_fund_name text;
BEGIN
    -- 1. Lấy thông tin đơn hàng + Tên NCC
    SELECT po.*, s.name as supplier_name_text
    INTO v_order
    FROM public.purchase_orders po
    LEFT JOIN public.suppliers s ON po.supplier_id = s.id
    WHERE po.id = p_order_id;

    IF v_order.id IS NULL THEN 
        RAISE EXCEPTION 'Không tìm thấy đơn mua hàng ID %', p_order_id; 
    END IF;

    -- 2. Validate Quỹ
    SELECT name INTO v_fund_name FROM public.fund_accounts WHERE id = p_fund_account_id;
    IF v_fund_name IS NULL THEN 
        RAISE EXCEPTION 'Quỹ không tồn tại (ID: %)', p_fund_account_id; 
    END IF;

    -- 3. Tính toán tiền
    v_new_paid := COALESCE(v_order.total_paid, 0) + p_amount;
    
    -- Xác định trạng thái (Cho phép sai số nhỏ 500đ)
    IF v_new_paid >= (v_order.final_amount - 500) THEN 
        v_status := 'paid'; 
    ELSE 
        v_status := 'partial'; 
    END IF;

    -- 4. Update Đơn Mua Hàng
    UPDATE public.purchase_orders
    SET 
        total_paid = v_new_paid,
        payment_status = v_status,
        updated_at = NOW()
    WHERE id = p_order_id;

    -- 5. Tạo Phiếu Chi (Payment Voucher)
    v_trans_code := public._gen_finance_tx_code('PC');

    INSERT INTO public.finance_transactions (
        code, 
        transaction_date, 
        flow,           -- 'out' (Chi)
        business_type,  -- 'trade' (Thương mại)
        amount, 
        fund_account_id,
        
        partner_type,       -- 'supplier'
        partner_id,         -- ID lưu text
        partner_name_cache, -- Cache tên
        
        ref_type,           -- 'purchase_order'
        ref_id,             -- ID đơn mua
        
        description, 
        created_by, 
        status
    ) VALUES (
        v_trans_code, 
        NOW(), 
        'out', 
        'trade', 
        p_amount, 
        p_fund_account_id,
        
        'supplier', 
        v_order.supplier_id::TEXT, 
        COALESCE(v_order.supplier_name_text, 'NCC Lẻ'),
        
        'purchase_order', 
        p_order_id::TEXT,
        
        COALESCE(p_note, 'Chi thanh toán PO-' || p_order_id || ' (' || p_payment_method || ')'),
        auth.uid(), 
        'completed' -- Trigger sẽ tự trừ tiền quỹ
    );

    RETURN jsonb_build_object(
        'success', true,
        'new_status', v_status,
        'paid_amount', v_new_paid,
        'trans_code', v_trans_code
    );
END;
$function$
