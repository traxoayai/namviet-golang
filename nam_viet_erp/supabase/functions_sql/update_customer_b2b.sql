CREATE OR REPLACE FUNCTION public.update_customer_b2b(p_customer_id bigint, p_customer_json jsonb, p_contacts_json jsonb DEFAULT '[]'::jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
BEGIN
  UPDATE public.customers
  SET 
    name = p_customer_json->>'name',
    phone = p_customer_json->>'phone',
    email = p_customer_json->>'email',
    status = COALESCE(p_customer_json->>'status', 'active'),
    tax_code = p_customer_json->>'tax_code',
    shipping_address = p_customer_json->>'shipping_address',
    vat_address = p_customer_json->>'vat_address',
    gps_lat = (p_customer_json->>'gps_lat')::numeric,
    gps_long = (p_customer_json->>'gps_long')::numeric,
    bank_name = p_customer_json->>'bank_name',
    bank_account_name = p_customer_json->>'bank_account_name',
    bank_account_number = p_customer_json->>'bank_account_number',
    updated_at = now()
  WHERE id = p_customer_id AND type = 'ToChuc';

  UPDATE public.customers_b2b
  SET
    debt_limit = COALESCE((p_customer_json->>'debt_limit')::numeric, debt_limit),
    payment_term = COALESCE((p_customer_json->>'payment_term')::integer, payment_term),
    ranking = p_customer_json->>'ranking',
    business_license_number = p_customer_json->>'business_license_number',
    business_license_url = p_customer_json->>'business_license_url',
    sales_staff_id = (p_customer_json->>'sales_staff_id')::uuid,
    sales_permissions = COALESCE(p_customer_json->'sales_permissions', sales_permissions),
    updated_at = now()
  WHERE customer_id = p_customer_id;

  DELETE FROM public.customer_b2b_contacts WHERE customer_id = p_customer_id;

  IF jsonb_array_length(p_contacts_json) > 0 THEN
    INSERT INTO public.customer_b2b_contacts (
      customer_id, name, position, phone, email
    )
    SELECT
      p_customer_id,
      contact->>'name',
      contact->>'position',
      contact->>'phone',
      contact->>'email'
    FROM jsonb_array_elements(p_contacts_json) AS contact;
  END IF;
END;
$function$
