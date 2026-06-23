CREATE OR REPLACE FUNCTION public.update_user_assignments(p_user_id uuid, p_assignments jsonb[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    assignment JSONB;
BEGIN
    -- A. Xóa tất cả phân quyền cũ của user này
    DELETE FROM public.user_roles WHERE user_id = p_user_id;

    -- B. Loop qua mảng và insert lại
    IF p_assignments IS NOT NULL THEN
        FOREACH assignment IN ARRAY p_assignments
        LOOP
            INSERT INTO public.user_roles (user_id, role_id, branch_id)
            VALUES (
                p_user_id,
                (assignment->>'roleId')::UUID,   -- Chú ý: Key là roleId (CamelCase) khớp với Frontend
                (assignment->>'branchId')::BIGINT -- Chú ý: Key là branchId
            );
        END LOOP;
    END IF;
END;
$function$
