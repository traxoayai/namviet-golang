CREATE OR REPLACE FUNCTION public.track_inventory_changes()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        IF NEW.updated_by IS NOT NULL THEN
            -- Case 5: Cập nhật Vị trí kệ
            IF (OLD.shelf_location IS DISTINCT FROM NEW.shelf_location) THEN
                INSERT INTO public.product_activity_logs (user_id, product_id, action_type, old_value, new_value)
                VALUES (NEW.updated_by, NEW.product_id, 'update_location', OLD.shelf_location, NEW.shelf_location);
            END IF;
        END IF;
        RETURN NEW;
    END;
    $function$
