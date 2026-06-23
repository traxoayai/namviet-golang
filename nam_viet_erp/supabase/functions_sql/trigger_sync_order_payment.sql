CREATE OR REPLACE FUNCTION public.trigger_sync_order_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
    -- [CASE 1] KHI PHIEU THU DUOC DUYET (Pending -> Completed)
    -- HOAC TAO MOI O TRANG THAI COMPLETED NGAY LAP TUC
    IF (TG_OP = 'INSERT' AND NEW.status = 'completed') OR
       (TG_OP = 'UPDATE' AND NEW.status = 'completed' AND OLD.status != 'completed') THEN

        -- Chi xu ly phieu Thu (flow='in') va loai tham chieu la Don hang (ref_type='order')
        IF NEW.flow = 'in' AND NEW.ref_type = 'order' THEN

            -- Chi cap nhat remittance info (KHONG cap nhat paid_amount - de cho auto_allocate_payment)
            UPDATE public.orders
            SET
                remittance_transaction_id = NEW.id,
                remittance_status = 'deposited',
                updated_at = NOW()
            WHERE code = NEW.ref_id;

        END IF;
    END IF;

    -- [CASE 2] KHI HUY PHIEU THU DA DUYET (Completed -> Cancelled)
    -- Tru lai tien va reset trang thai neu lo duyet sai
    IF (TG_OP = 'UPDATE' AND NEW.status = 'cancelled' AND OLD.status = 'completed') THEN

        IF NEW.flow = 'in' AND NEW.ref_type = 'order' THEN
            UPDATE public.orders
            SET
                -- Tru so tien cua phieu bi huy (Khong cho phep am)
                paid_amount = GREATEST(0, COALESCE(paid_amount, 0) - OLD.amount),

                -- Go thong tin doi soat cua phieu nay
                remittance_transaction_id = NULL,
                remittance_status = 'pending',

                -- Tinh lai trang thai thanh toan dua tren so tien con lai
                payment_status = CASE
                    WHEN (GREATEST(0, COALESCE(paid_amount, 0) - OLD.amount)) >= final_amount THEN 'paid'
                    WHEN (GREATEST(0, COALESCE(paid_amount, 0) - OLD.amount)) > 0 THEN 'partial'
                    ELSE 'unpaid'
                END,

                updated_at = NOW()
            WHERE code = NEW.ref_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$function$
