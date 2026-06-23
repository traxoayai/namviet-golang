CREATE OR REPLACE FUNCTION public.fn_task_status_notify()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_changer_id UUID := auth.uid();
    v_target_user_id UUID;
    v_title TEXT;
    v_message TEXT; -- Đổi biến thành v_message cho đồng bộ
BEGIN
    -- Chỉ kích hoạt khi Trạng thái bị thay đổi
    IF NEW.status IS DISTINCT FROM OLD.status THEN
        
        -- TH1: Người đổi là Người nhận việc -> Báo cho Người giao việc
        IF v_changer_id = NEW.assignee_id AND NEW.assigner_id IS NOT NULL THEN
            v_target_user_id := NEW.assigner_id;
            v_title := 'Tiến độ công việc được cập nhật';
            v_message := 'Nhân viên vừa cập nhật task "' || NEW.title || '" sang trạng thái: ' || UPPER(NEW.status);
            
        -- TH2: Người đổi là Người giao việc HOẶC Hệ thống AI (v_changer_id IS NULL) -> Báo cho Người nhận
        ELSIF v_changer_id = NEW.assigner_id OR v_changer_id IS NULL THEN
            v_target_user_id := NEW.assignee_id;
            v_title := 'Thay đổi từ Quản lý / Hệ thống';
            v_message := 'Công việc "' || NEW.title || '" của bạn đã được chuyển sang: ' || UPPER(NEW.status);
            
        -- TH3: Admin/Người khác can thiệp -> Báo cho Người nhận
        ELSE
            v_target_user_id := NEW.assignee_id;
            v_title := 'Cập nhật hệ thống';
            v_message := 'Trạng thái công việc "' || NEW.title || '" đã bị đổi thành: ' || UPPER(NEW.status);
        END IF;

        -- Insert thông báo (Chỉ định đúng cột 'message')
        IF v_target_user_id IS NOT NULL AND (v_target_user_id != v_changer_id OR v_changer_id IS NULL) THEN
            INSERT INTO public.notifications (user_id, title, message, type, reference_id)
            VALUES (v_target_user_id, v_title, v_message, 'task_update', NEW.id);
        END IF;
        
    END IF;
    RETURN NEW;
END;
$function$
