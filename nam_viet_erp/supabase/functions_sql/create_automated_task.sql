CREATE OR REPLACE FUNCTION public.create_automated_task(p_title text, p_description text, p_priority text, p_due_date timestamp with time zone, p_assignee_id uuid, p_entity_type text DEFAULT 'none'::text, p_entity_id text DEFAULT NULL::text, p_ai_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_task_id UUID;
BEGIN
    INSERT INTO public.tasks (
        title, description, priority, due_date, 
        assigner_id, assignee_id, entity_type, entity_id, ai_metadata
    ) VALUES (
        p_title, p_description, p_priority, p_due_date, 
        NULL, -- NULL mang ý nghĩa: Hệ thống/AI tự động tạo
        p_assignee_id, p_entity_type, p_entity_id, p_ai_metadata
    ) RETURNING id INTO v_task_id;

    RETURN jsonb_build_object(
        'success', true, 
        'task_id', v_task_id, 
        'message', 'Task tự động đã được ghim vào sổ việc của nhân viên!'
    );
END;
$function$
