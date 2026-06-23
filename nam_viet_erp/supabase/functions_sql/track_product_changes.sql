CREATE OR REPLACE FUNCTION public.track_product_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- Chỉ ghi log nếu có người thực hiện (updated_by không null)
        IF NEW.updated_by IS NOT NULL THEN
            
            -- Case 1: Cập nhật Barcode
            IF (OLD.barcode IS DISTINCT FROM NEW.barcode) THEN
                INSERT INTO public.product_activity_logs (user_id, product_id, action_type, old_value, new_value)
                VALUES (NEW.updated_by, NEW.id, 'update_barcode', OLD.barcode, NEW.barcode);
            END IF;

            -- Case 2: Cập nhật Đơn vị (Wholesale Unit)
            IF (OLD.wholesale_unit IS DISTINCT FROM NEW.wholesale_unit) THEN
                INSERT INTO public.product_activity_logs (user_id, product_id, action_type, old_value, new_value)
                VALUES (NEW.updated_by, NEW.id, 'update_unit', OLD.wholesale_unit, NEW.wholesale_unit);
            END IF;

             -- Case 3: Cập nhật Nội dung/Tên (Content)
            IF (OLD.description IS DISTINCT FROM NEW.description) OR (OLD.name IS DISTINCT FROM NEW.name) THEN
                INSERT INTO public.product_activity_logs (user_id, product_id, action_type, old_value, new_value)
                VALUES (NEW.updated_by, NEW.id, 'update_content', 'old_content', 'new_content');
            END IF;

            -- Case 4: Cập nhật Giá bán (Invoice Price) - Thêm cái này để quản lý chặt hơn
            IF (OLD.invoice_price IS DISTINCT FROM NEW.invoice_price) THEN
                 INSERT INTO public.product_activity_logs (user_id, product_id, action_type, old_value, new_value)
                VALUES (NEW.updated_by, NEW.id, 'update_price', OLD.invoice_price::text, NEW.invoice_price::text);
            END IF;

        END IF;
        RETURN NEW;
    END;
    $function$
