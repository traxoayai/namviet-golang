CREATE OR REPLACE FUNCTION public.get_profit_and_loss(p_start_date date, p_end_date date, p_book text)
 RETURNS TABLE(item_code text, item_name text, current_period_amount numeric, previous_period_amount numeric)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
    v_rev_511 numeric := 0;
    v_rev_dec_521 numeric := 0;
    v_net_rev numeric := 0;
    v_cogs_632 numeric := 0;
    v_gross_profit numeric := 0;
    v_fin_rev_515 numeric := 0;
    v_fin_exp_615 numeric := 0;
    v_sale_exp_641 numeric := 0;
    v_admin_exp_642 numeric := 0;
    v_net_profit numeric := 0;
    v_other_inc_711 numeric := 0;
    v_other_exp_811 numeric := 0;
    v_other_profit numeric := 0;
    v_total_profit_before_tax numeric := 0;
    v_tax_exp_821 numeric := 0;
    v_net_profit_after_tax numeric := 0;
BEGIN
    -- Doanh thu = Có - Nợ (Loại trừ bút toán Khóa sổ - closing)
    -- Chi phí = Nợ - Có (Loại trừ bút toán Khóa sổ - closing)
    
    WITH period_data AS (
        SELECT 
            SUBSTRING(coa.account_code FROM 1 FOR 3) AS acc_prefix,
            COALESCE(SUM(l.credit - l.debit), 0) AS net_credit,
            COALESCE(SUM(l.debit - l.credit), 0) AS net_debit
        FROM chart_of_accounts coa
        JOIN journal_entry_lines l ON coa.id = l.account_id
        JOIN journal_entries e ON l.entry_id = e.id
        WHERE e.status = 'posted' 
          AND (e.book = p_book OR e.book = 'BOTH')
          AND e.entry_date >= p_start_date 
          AND e.entry_date <= p_end_date
          AND e.doc_type != 'closing'
        GROUP BY SUBSTRING(coa.account_code FROM 1 FOR 3)
    )
    SELECT
        MAX(CASE WHEN acc_prefix = '511' THEN net_credit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '521' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '632' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '515' THEN net_credit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '615' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '641' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '642' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '711' THEN net_credit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '811' THEN net_debit ELSE 0 END),
        MAX(CASE WHEN acc_prefix = '821' THEN net_debit ELSE 0 END)
    INTO
        v_rev_511,
        v_rev_dec_521,
        v_cogs_632,
        v_fin_rev_515,
        v_fin_exp_615,
        v_sale_exp_641,
        v_admin_exp_642,
        v_other_inc_711,
        v_other_exp_811,
        v_tax_exp_821
    FROM period_data;

    -- Handle nulls if missing
    v_rev_511 := COALESCE(v_rev_511, 0);
    v_rev_dec_521 := COALESCE(v_rev_dec_521, 0);
    v_cogs_632 := COALESCE(v_cogs_632, 0);
    v_fin_rev_515 := COALESCE(v_fin_rev_515, 0);
    v_fin_exp_615 := COALESCE(v_fin_exp_615, 0);
    v_sale_exp_641 := COALESCE(v_sale_exp_641, 0);
    v_admin_exp_642 := COALESCE(v_admin_exp_642, 0);
    v_other_inc_711 := COALESCE(v_other_inc_711, 0);
    v_other_exp_811 := COALESCE(v_other_exp_811, 0);
    v_tax_exp_821 := COALESCE(v_tax_exp_821, 0);

    -- Calculations
    v_net_rev := v_rev_511 - v_rev_dec_521;
    v_gross_profit := v_net_rev - v_cogs_632;
    v_net_profit := v_gross_profit + v_fin_rev_515 - v_fin_exp_615 - v_sale_exp_641 - v_admin_exp_642;
    v_other_profit := v_other_inc_711 - v_other_exp_811;
    v_total_profit_before_tax := v_net_profit + v_other_profit;
    v_net_profit_after_tax := v_total_profit_before_tax - v_tax_exp_821;

    -- Build return table
    item_code := '01'; item_name := '1. Doanh thu bán hàng và cung cấp dịch vụ'; current_period_amount := v_rev_511; previous_period_amount := 0; RETURN NEXT;
    item_code := '02'; item_name := '2. Các khoản giảm trừ doanh thu'; current_period_amount := v_rev_dec_521; previous_period_amount := 0; RETURN NEXT;
    item_code := '10'; item_name := '3. Doanh thu thuần về bán hàng và CCDV'; current_period_amount := v_net_rev; previous_period_amount := 0; RETURN NEXT;
    item_code := '11'; item_name := '4. Giá vốn hàng bán'; current_period_amount := v_cogs_632; previous_period_amount := 0; RETURN NEXT;
    item_code := '20'; item_name := '5. Lợi nhuận gộp về bán hàng và CCDV'; current_period_amount := v_gross_profit; previous_period_amount := 0; RETURN NEXT;
    item_code := '21'; item_name := '6. Doanh thu hoạt động tài chính'; current_period_amount := v_fin_rev_515; previous_period_amount := 0; RETURN NEXT;
    item_code := '22'; item_name := '7. Chi phí tài chính'; current_period_amount := v_fin_exp_615; previous_period_amount := 0; RETURN NEXT;
    item_code := '25'; item_name := '8. Chi phí bán hàng'; current_period_amount := v_sale_exp_641; previous_period_amount := 0; RETURN NEXT;
    item_code := '26'; item_name := '9. Chi phí quản lý doanh nghiệp'; current_period_amount := v_admin_exp_642; previous_period_amount := 0; RETURN NEXT;
    item_code := '30'; item_name := '10. Lợi nhuận thuần từ hoạt động kinh doanh'; current_period_amount := v_net_profit; previous_period_amount := 0; RETURN NEXT;
    item_code := '31'; item_name := '11. Thu nhập khác'; current_period_amount := v_other_inc_711; previous_period_amount := 0; RETURN NEXT;
    item_code := '32'; item_name := '12. Chi phí khác'; current_period_amount := v_other_exp_811; previous_period_amount := 0; RETURN NEXT;
    item_code := '40'; item_name := '13. Lợi nhuận khác'; current_period_amount := v_other_profit; previous_period_amount := 0; RETURN NEXT;
    item_code := '50'; item_name := '14. Tổng lợi nhuận kế toán trước thuế'; current_period_amount := v_total_profit_before_tax; previous_period_amount := 0; RETURN NEXT;
    item_code := '51'; item_name := '15. Chi phí thuế TNDN'; current_period_amount := v_tax_exp_821; previous_period_amount := 0; RETURN NEXT;
    item_code := '60'; item_name := '16. Lợi nhuận sau thuế TNDN'; current_period_amount := v_net_profit_after_tax; previous_period_amount := 0; RETURN NEXT;
END;
$function$
