CREATE OR REPLACE FUNCTION public.get_service_package_details(p_id bigint)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_details JSONB;
BEGIN
  SELECT
    jsonb_build_object(
      -- 1. Thông tin chính (từ bảng 'service_packages')
      'package_data', to_jsonb(p.*),
      
      -- 2. Gom mảng items con (từ bảng 'service_package_items')
      'package_items', (
        SELECT COALESCE(jsonb_agg(
          jsonb_build_object(
            'key', i.id,
            'item_id', i.item_id,
            'quantity', i.quantity,
            'item_type', i.item_type,
            'schedule_days', i.schedule_days,
            -- Tích hợp: Lấy tên và đơn vị từ bảng 'products'
            'name', prod.name,
            'unit', prod.retail_unit -- Mặc định lấy đơn vị lẻ
          )
        ), '[]'::JSONB)
        FROM public.service_package_items i
        JOIN public.products prod ON i.item_id = prod.id
        WHERE i.package_id = p.id
      )
    )
  INTO v_details
  FROM public.service_packages p
  WHERE p.id = p_id;
  
  RETURN v_details;
END;
$function$
