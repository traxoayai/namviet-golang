CREATE OR REPLACE FUNCTION public.fn_protect_task_columns()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN
    -- Nếu người đang sửa là Người nhận việc (Và không đồng thời là người giao việc)
    IF auth.uid() = NEW.assignee_id AND auth.uid() IS DISTINCT FROM OLD.assigner_id THEN
        -- Cấm sửa Deadline, Priority, Entity
        IF NEW.due_date IS DISTINCT FROM OLD.due_date 
           OR NEW.priority IS DISTINCT FROM OLD.priority 
           OR NEW.entity_type IS DISTINCT FROM OLD.entity_type THEN
            RAISE EXCEPTION 'BẢO MẬT: Bạn không có quyền sửa Deadline, Độ ưu tiên hay Ngữ cảnh của Task này!';
        END IF;
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$function$
