CREATE OR REPLACE FUNCTION public.delete_service_packages(p_ids bigint[])
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    BEGIN
        -- Cập nhật trạng thái sang 'deleted' cho các ID nằm trong danh sách
        UPDATE public.service_packages
        SET 
            status = 'deleted',
            updated_at = NOW()
        WHERE id = ANY(p_ids);
        
        -- (Optional) Có thể xóa mềm luôn các items con trong service_package_items nếu cần,
        -- nhưng thường giữ nguyên để truy vết lịch sử gói lúc xóa gồm những gì.
    END;
    $function$
