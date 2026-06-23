CREATE OR REPLACE FUNCTION public.bulk_update_product_barcodes(p_data jsonb)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    item jsonb;
    v_product_id bigint;
    v_base_barcode text;
    v_wholesale_barcode text;
BEGIN
    FOR item IN SELECT * FROM jsonb_array_elements(p_data)
    LOOP
        v_product_id := (item->>'product_id')::bigint;
        v_base_barcode := NULLIF(TRIM(item->>'base_barcode'), '');
        v_wholesale_barcode := NULLIF(TRIM(item->>'wholesale_barcode'), '');

        IF v_base_barcode IS NOT NULL THEN
            UPDATE public.product_units
            SET barcode = v_base_barcode
            WHERE product_id = v_product_id AND is_base = true;
        END IF;

        IF v_wholesale_barcode IS NOT NULL THEN
            UPDATE public.product_units
            SET barcode = v_wholesale_barcode
            WHERE product_id = v_product_id AND unit_type = 'wholesale';
            
            UPDATE public.products
            SET barcode = v_wholesale_barcode
            WHERE id = v_product_id;
        END IF;
    END LOOP;
END;
$function$
