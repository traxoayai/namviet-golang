CREATE OR REPLACE FUNCTION public.create_service_package(p_data jsonb, p_items jsonb)
 RETURNS bigint
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_package_id BIGINT;
  v_calculated_cost NUMERIC;
  v_item JSONB;
BEGIN
  v_calculated_cost := public.calculate_package_cost(p_items);

  INSERT INTO public.service_packages (
    name, sku, unit, type, price, total_cost_price, revenue_account_id,
    valid_from, valid_to, status, validity_days, applicable_branches, applicable_channels,
    clinical_category -- [MỚI THÊM]
  )
  VALUES (
    p_data->>'name', p_data->>'sku', p_data->>'unit', (p_data->>'type')::public.service_package_type,
    (p_data->>'price')::NUMERIC, v_calculated_cost, p_data->>'revenueAccountId',
    (p_data->>'validFrom')::DATE, (p_data->>'validTo')::DATE, (p_data->>'status')::public.account_status,
    (p_data->>'validityDays')::INT, 
    (SELECT array_agg(value::BIGINT) FROM jsonb_array_elements_text(p_data->'applicableBranches') AS t(value)),
    p_data->>'applicableChannels',
    COALESCE(p_data->>'clinicalCategory', 'none') -- [MỚI THÊM] Hứng từ JSON (FE sẽ gửi clinicalCategory)
  )
  RETURNING id INTO v_package_id;

  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO public.service_package_items (package_id, item_id, quantity, item_type, schedule_days)
    VALUES (v_package_id, (v_item->>'item_id')::BIGINT, (v_item->>'quantity')::NUMERIC, (v_item->>'item_type')::TEXT, (v_item->>'schedule_days')::INT);
  END LOOP;
  
  RETURN v_package_id;
END;
$function$
