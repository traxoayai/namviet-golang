CREATE OR REPLACE FUNCTION public.handle_sales_inventory_deduction()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
    BEGIN
        -- [CORE FIX]: Đã vô hiệu hóa logic trừ kho tại đây.
        -- Việc trừ kho và ghi nhận giá vốn sẽ được thực hiện tại hàm confirm_outbound_packing (lúc đóng gói).
        -- Trigger này hiện tại chỉ đóng vai trò placeholder để không gây lỗi hệ thống.
        RETURN NEW;
    END;
    $function$
