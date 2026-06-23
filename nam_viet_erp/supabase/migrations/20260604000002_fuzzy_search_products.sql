-- Kích hoạt extension unaccent
CREATE EXTENSION IF NOT EXISTS unaccent;

-- Nâng cấp RPC search_products_for_quick_barcode_page
CREATE OR REPLACE FUNCTION public.search_products_for_quick_barcode_page(search_term text, p_offset integer, p_limit integer)
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_search_unaccent text := unaccent(search_term);
    v_words text[];
    v_count integer;
    v_data jsonb;
BEGIN
    IF search_term IS NULL OR trim(search_term) = '' THEN
        SELECT count(*) INTO v_count FROM products WHERE status = 'active';
        
        SELECT COALESCE(jsonb_agg(
            jsonb_build_object(
                'id', p.id,
                'name', p.name,
                'sku', p.sku,
                'product_barcode', p.barcode,
                'image_url', p.image_url,
                'retail_unit', p.retail_unit,
                'wholesale_unit', p.wholesale_unit,
                'units', COALESCE((
                    SELECT jsonb_agg(jsonb_build_object(
                        'unit_name', pu.unit_name,
                        'barcode', pu.barcode,
                        'is_base', pu.is_base,
                        'unit_type', pu.unit_type
                    ))
                    FROM product_units pu
                    WHERE pu.product_id = p.id
                ), '[]'::jsonb)
            )
        ), '[]'::jsonb) INTO v_data
        FROM (
            SELECT * FROM products
            WHERE status = 'active'
            ORDER BY created_at DESC
            OFFSET p_offset LIMIT p_limit
        ) p;
    ELSE
        v_words := string_to_array(trim(v_search_unaccent), ' ');
        
        WITH matched_products AS (
            SELECT p.* FROM products p
            WHERE p.status = 'active'
            AND (
                (
                    SELECT bool_and(unaccent(p.name) ILIKE '%' || w || '%')
                    FROM unnest(v_words) w
                )
                OR unaccent(p.sku) ILIKE '%' || trim(v_search_unaccent) || '%'
                OR p.barcode ILIKE '%' || trim(search_term) || '%'
            )
            ORDER BY p.created_at DESC
        )
        SELECT count(*),
            COALESCE(
                jsonb_agg(
                    jsonb_build_object(
                        'id', mp.id,
                        'name', mp.name,
                        'sku', mp.sku,
                        'product_barcode', mp.barcode,
                        'image_url', mp.image_url,
                        'retail_unit', mp.retail_unit,
                        'wholesale_unit', mp.wholesale_unit,
                        'units', COALESCE((
                            SELECT jsonb_agg(jsonb_build_object(
                                'unit_name', pu.unit_name,
                                'barcode', pu.barcode,
                                'is_base', pu.is_base,
                                'unit_type', pu.unit_type
                            ))
                            FROM product_units pu
                            WHERE pu.product_id = mp.id
                        ), '[]'::jsonb)
                    )
                ),
                '[]'::jsonb
            )
        INTO v_count, v_data
        FROM (
            SELECT * FROM matched_products
            OFFSET p_offset LIMIT p_limit
        ) mp;
    END IF;
    
    RETURN jsonb_build_object('count', v_count, 'data', COALESCE(v_data, '[]'::jsonb));
END;
$function$;

-- Nâng cấp RPC bulk_update_product_barcodes để cập nhật products.barcode
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
$function$;
