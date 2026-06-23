CREATE OR REPLACE FUNCTION public.handle_fund_balance_update()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- TRƯỜNG HỢP 1: HOÀN TẤT PHIẾU (Tiền thực sự di chuyển)
    -- Xảy ra khi chuyển từ bất kỳ trạng thái nào (pending/approved) sang 'completed'
    IF (TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed') 
       OR (TG_OP = 'INSERT' AND NEW.status = 'completed') THEN
       
        IF NEW.flow = 'in' THEN
            UPDATE public.fund_accounts 
            SET balance = balance + NEW.amount, updated_at = now() 
            WHERE id = NEW.fund_account_id;
        ELSIF NEW.flow = 'out' THEN
            UPDATE public.fund_accounts 
            SET balance = balance - NEW.amount, updated_at = now() 
            WHERE id = NEW.fund_account_id;
        END IF;

    -- TRƯỜNG HỢP 2: HỦY PHIẾU ĐÃ HOÀN TẤT (Rollback tiền)
    -- Chỉ khi phiếu cũ là 'completed' thì mới cần hoàn tiền lại quỹ
    ELSIF (TG_OP = 'UPDATE' AND NEW.status = 'cancelled' AND OLD.status = 'completed') THEN
        IF OLD.flow = 'in' THEN
            UPDATE public.fund_accounts SET balance = balance - OLD.amount WHERE id = OLD.fund_account_id;
        ELSIF OLD.flow = 'out' THEN
            UPDATE public.fund_accounts SET balance = balance + OLD.amount WHERE id = OLD.fund_account_id;
        END IF;

    -- TRƯỜNG HỢP 3: XÓA PHIẾU ĐÃ HOÀN TẤT
    ELSIF (TG_OP = 'DELETE' AND OLD.status = 'completed') THEN
        IF OLD.flow = 'in' THEN
            UPDATE public.fund_accounts SET balance = balance - OLD.amount WHERE id = OLD.fund_account_id;
        ELSIF OLD.flow = 'out' THEN
            UPDATE public.fund_accounts SET balance = balance + OLD.amount WHERE id = OLD.fund_account_id;
        END IF;
    END IF;

    -- LƯU Ý: Các trạng thái 'pending' hay 'approved' KHÔNG làm thay đổi số dư.
    
    RETURN NULL;
END;
$function$
