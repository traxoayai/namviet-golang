CREATE OR REPLACE FUNCTION public.fn_trigger_update_debt_from_orders()
 RETURNS trigger
 LANGUAGE plpgsql
AS $function$
DECLARE
    v_is_debt_status_old BOOLEAN;
    v_is_debt_status_new BOOLEAN;
BEGIN
    -- Chỉ xử lý đơn có customer_id (B2B)
    -- NEW.customer_id cho INSERT/UPDATE, OLD.customer_id cho DELETE
    
    -- Danh sách trạng thái tính nợ: PACKED, SHIPPING, DELIVERED, COMPLETED
    -- (Trạng thái CONFIRMED không tính nợ theo yêu cầu)

    -- [Xử lý DELETE]
    IF (TG_OP = 'DELETE') THEN
        IF OLD.customer_id IS NOT NULL THEN
            v_is_debt_status_old := (OLD.status IN ('PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED'));
            IF v_is_debt_status_old THEN
                UPDATE public.customers_b2b
                SET current_debt = COALESCE(current_debt, 0) - OLD.final_amount
                WHERE id = OLD.customer_id;
            END IF;
        END IF;
        RETURN OLD;
    END IF;

    -- [Xử lý INSERT]
    IF (TG_OP = 'INSERT') THEN
        IF NEW.customer_id IS NOT NULL THEN
            v_is_debt_status_new := (NEW.status IN ('PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED'));
            IF v_is_debt_status_new THEN
                UPDATE public.customers_b2b
                SET current_debt = COALESCE(current_debt, 0) + NEW.final_amount
                WHERE id = NEW.customer_id;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    -- [Xử lý UPDATE]
    IF (TG_OP = 'UPDATE') THEN
        IF NEW.customer_id IS NOT NULL THEN
            v_is_debt_status_old := (OLD.status IN ('PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED'));
            v_is_debt_status_new := (NEW.status IN ('PACKED', 'SHIPPING', 'DELIVERED', 'COMPLETED'));

            -- Case 1: Chuyển từ trạng thái KHÔNG nợ -> CÓ nợ
            IF NOT v_is_debt_status_old AND v_is_debt_status_new THEN
                UPDATE public.customers_b2b
                SET current_debt = COALESCE(current_debt, 0) + NEW.final_amount
                WHERE id = NEW.customer_id;
            
            -- Case 2: Chuyển từ trạng thái CÓ nợ -> KHÔNG nợ (Hủy/Quay lại confirmed)
            ELSIF v_is_debt_status_old AND NOT v_is_debt_status_new THEN
                UPDATE public.customers_b2b
                SET current_debt = COALESCE(current_debt, 0) - OLD.final_amount
                WHERE id = NEW.customer_id;

            -- Case 3: Vẫn ở trạng thái CÓ nợ nhưng thay đổi số tiền hoặc đổi khách hàng
            ELSIF v_is_debt_status_old AND v_is_debt_status_new THEN
                -- Nếu đổi khách hàng
                IF OLD.customer_id != NEW.customer_id THEN
                    -- Trừ khách cũ
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) - OLD.final_amount WHERE id = OLD.customer_id;
                    -- Cộng khách mới
                    UPDATE public.customers_b2b SET current_debt = COALESCE(current_debt, 0) + NEW.final_amount WHERE id = NEW.customer_id;
                -- Nếu cùng khách nhưng đổi số tiền
                ELSIF OLD.final_amount != NEW.final_amount THEN
                    UPDATE public.customers_b2b
                    SET current_debt = COALESCE(current_debt, 0) + (NEW.final_amount - OLD.final_amount)
                    WHERE id = NEW.customer_id;
                END IF;
            END IF;
        END IF;
        RETURN NEW;
    END IF;

    RETURN NULL;
END;
$function$
