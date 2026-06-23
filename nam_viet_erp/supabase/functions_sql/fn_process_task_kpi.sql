CREATE OR REPLACE FUNCTION public.fn_process_task_kpi()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Chỉ kích hoạt khi trạng thái đổi thành 'done'
    IF NEW.status = 'done' AND OLD.status <> 'done' THEN
        NEW.completed_at = NOW();
        
        -- Gamification Logic
        IF NEW.completed_at <= NEW.due_date THEN
            NEW.kpi_points = 10; -- Hoàn thành đúng/sớm hạn: Thưởng tối đa
        ELSE
            NEW.kpi_points = 5;  -- Trễ hạn: Vẫn thưởng nhưng bị trừ nửa
        END IF;
    END IF;

    -- Nếu hủy task, thu hồi điểm
    IF NEW.status = 'cancelled' THEN
        NEW.completed_at = NULL;
        NEW.kpi_points = 0;
    END IF;

    RETURN NEW;
END;
$function$
