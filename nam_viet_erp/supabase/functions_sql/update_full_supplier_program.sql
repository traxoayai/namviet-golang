CREATE OR REPLACE FUNCTION public.update_full_supplier_program(p_program_id bigint, p_program_data jsonb, p_groups_data jsonb)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_group JSONB;
    v_group_id BIGINT;
    v_exists BOOLEAN;
BEGIN
    -- 1. Validation: Kiểm tra ID tồn tại
    SELECT EXISTS(SELECT 1 FROM public.supplier_programs WHERE id = p_program_id) INTO v_exists;
    IF NOT v_exists THEN
        RAISE EXCEPTION 'Chương trình/Hợp đồng ID % không tồn tại.', p_program_id;
    END IF;

    -- 2. Update Header (Thông tin chung)
    UPDATE public.supplier_programs
    SET 
        supplier_id = COALESCE((p_program_data->>'supplier_id')::BIGINT, supplier_id),
        code = p_program_data->>'code',
        name = p_program_data->>'name',
        type = (p_program_data->>'type')::public.supplier_program_type,
        valid_from = (p_program_data->>'valid_from')::DATE,
        valid_to = (p_program_data->>'valid_to')::DATE,
        document_code = p_program_data->>'document_code',
        attachment_url = p_program_data->>'attachment_url',
        description = p_program_data->>'description',
        updated_at = NOW()
    WHERE id = p_program_id;

    -- 3. Xử lý Groups & Products (Chiến lược: Replace All)
    -- Xóa các nhóm cũ thuộc chương trình này. 
    -- (Các sản phẩm thuộc nhóm sẽ tự động bị xóa theo nhờ ON DELETE CASCADE tại bảng supplier_program_products)
    DELETE FROM public.supplier_program_groups WHERE program_id = p_program_id;

    -- 4. Insert lại Groups mới (Vòng lặp)
    FOR v_group IN SELECT * FROM jsonb_array_elements(p_groups_data)
    LOOP
        INSERT INTO public.supplier_program_groups (
            program_id, name, rule_type, rules, price_basis
        ) VALUES (
            p_program_id,
            v_group->>'name',
            v_group->>'rule_type',
            v_group->'rules',
            COALESCE(v_group->>'price_basis', 'pre_vat')
        ) RETURNING id INTO v_group_id;

        -- Insert Products cho Group này
        -- Sử dụng INSERT SELECT UNNEST để tối ưu hiệu năng
        IF (v_group->'product_ids') IS NOT NULL THEN
            INSERT INTO public.supplier_program_products (group_id, product_id)
            SELECT v_group_id, (value::BIGINT)
            FROM jsonb_array_elements_text(v_group->'product_ids');
        END IF;
    END LOOP;

    RETURN jsonb_build_object('success', true, 'message', 'Cập nhật chính sách thành công');
END;
$function$
