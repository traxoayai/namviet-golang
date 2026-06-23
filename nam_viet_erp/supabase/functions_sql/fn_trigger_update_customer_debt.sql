CREATE OR REPLACE FUNCTION public.fn_trigger_update_customer_debt()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_diff numeric;
BEGIN
    -- [CASE 1]: INSERT
    IF (TG_OP = 'INSERT') AND NEW.status = 'completed' THEN
        IF NEW.partner_type = 'customer_b2b' AND NEW.partner_id IS NOT NULL THEN
            IF NEW.flow = 'in' THEN
                UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - NEW.amount WHERE id = NEW.partner_id::bigint;
            ELSIF NEW.flow = 'out' THEN
                UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + NEW.amount WHERE id = NEW.partner_id::bigint;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- [CASE 2]: UPDATE
    IF (TG_OP = 'UPDATE') THEN
        -- A. Nếu trạng thái chuyển sang 'completed' (Duyệt phiếu)
        IF OLD.status != 'completed' AND NEW.status = 'completed' THEN
            IF NEW.partner_type = 'customer_b2b' AND NEW.partner_id IS NOT NULL THEN
                IF NEW.flow = 'in' THEN
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - NEW.amount WHERE id = NEW.partner_id::bigint;
                ELSIF NEW.flow = 'out' THEN
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + NEW.amount WHERE id = NEW.partner_id::bigint;
                END IF;
            END IF;
        -- B. Nếu hủy duyệt phiếu
        ELSIF OLD.status = 'completed' AND NEW.status != 'completed' THEN
            IF NEW.partner_type = 'customer_b2b' AND NEW.partner_id IS NOT NULL THEN
                IF NEW.flow = 'in' THEN
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + OLD.amount WHERE id = OLD.partner_id::bigint;
                ELSIF NEW.flow = 'out' THEN
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - OLD.amount WHERE id = OLD.partner_id::bigint;
                END IF;
            END IF;
        -- C. Nếu đã 'completed' mà sửa số tiền
        ELSIF OLD.status = 'completed' AND NEW.status = 'completed' THEN
            IF NEW.partner_type = 'customer_b2b' AND NEW.partner_id IS NOT NULL THEN
                v_diff := NEW.amount - OLD.amount;
                IF v_diff != 0 THEN
                    IF NEW.flow = 'in' THEN
                        UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - v_diff WHERE id = NEW.partner_id::bigint;
                    ELSIF NEW.flow = 'out' THEN
                        UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + v_diff WHERE id = NEW.partner_id::bigint;
                    END IF;
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- [CASE 3]: DELETE
    IF (TG_OP = 'DELETE') AND OLD.status = 'completed' THEN
        IF OLD.partner_type = 'customer_b2b' AND OLD.partner_id IS NOT NULL THEN
            IF OLD.flow = 'in' THEN
                -- Xóa phiếu thu -\u003e Trả lại nợ (Tăng nợ)
                UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + OLD.amount WHERE id = OLD.partner_id::bigint;
            ELSIF OLD.flow = 'out' THEN
                -- Xóa phiếu chi -\u003e Giảm nợ
                UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - OLD.amount WHERE id = OLD.partner_id::bigint;
            END IF;
        END IF;
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$function$
