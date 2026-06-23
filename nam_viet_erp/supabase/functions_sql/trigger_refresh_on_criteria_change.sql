CREATE OR REPLACE FUNCTION public.trigger_refresh_on_criteria_change()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- Chỉ chạy logic nếu loại là 'dynamic'
        IF NEW.type = 'dynamic' THEN
            -- Kiểm tra: Nếu cột criteria thay đổi HOẶC cột type thay đổi (từ static -> dynamic)
            IF (OLD.criteria IS DISTINCT FROM NEW.criteria) OR (OLD.type IS DISTINCT FROM NEW.type) THEN
                -- Gọi hàm Refresh mà chúng ta đã viết ở lệnh trước
                PERFORM public.refresh_segment_members(NEW.id);
            END IF;
        END IF;
        
        RETURN NEW;
    END;
    $function$
