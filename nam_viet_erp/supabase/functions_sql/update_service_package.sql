CREATE OR REPLACE FUNCTION public.update_service_package(p_id bigint, p_data jsonb, p_items jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
  v_calculated_cost NUMERIC;
  v_item JSONB;
BEGIN
  v_calculated_cost := public.calculate_package_cost(p_items);

  UPDATE public.service_packages
  SET
    name = p_data->>'name', sku = p_data->>'sku', unit = p_data->>'unit',
    type = (p_data->>'type')::public.service_package_type, price = (p_data->>'price')::NUMERIC,
    total_cost_price = v_calculated_cost, revenue_account_id = p_data->>'revenueAccountId',
    valid_from = (p_data->>'validFrom')::DATE, valid_to = (p_data->>'validTo')::DATE,
    status = (p_data->>'status')::public.account_status, validity_days = (p_data->>'validityDays')::INT,
    applicable_branches = (SELECT array_agg(value::BIGINT) FROM jsonb_array_elements_text(p_data->'applicableBranches') AS t(value)),
    applicable_channels = p_data->>'applicableChannels',
    clinical_category = COALESCE(p_data->>'clinicalCategory', clinical_category), -- [MỚI THÊM]
    updated_at = now()
  WHERE id = p_id;

  DELETE FROM public.service_package_items WHERE package_id = p_id;
  
  FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
  LOOP
    INSERT INTO public.service_package_items (package_id, item_id, quantity, item_type, schedule_days)
    VALUES (p_id, (v_item->>'item_id')::BIGINT, (v_item->>'quantity')::NUMERIC, (v_item->>'item_type')::TEXT, (v_item->>'schedule_days')::INT);
  END LOOP;
END;
$function$
