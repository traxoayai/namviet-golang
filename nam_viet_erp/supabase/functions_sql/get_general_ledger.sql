CREATE OR REPLACE FUNCTION public.get_general_ledger(p_account_id uuid, p_start_date date, p_end_date date, p_book text)
 RETURNS TABLE(is_opening_balance boolean, transaction_date date, doc_id text, doc_type text, description text, cor_account_code text, debit numeric, credit numeric, running_balance numeric)
 LANGUAGE plpgsql
AS $function$
      DECLARE
          v_balance_type text;
          v_opening_debit numeric := 0;
          v_opening_credit numeric := 0;
          v_opening_balance numeric := 0;
      BEGIN
          -- 1. Get account balance type
          SELECT balance_type::text INTO v_balance_type
          FROM chart_of_accounts
          WHERE id = p_account_id;

          IF NOT FOUND THEN
             RAISE EXCEPTION 'Account not found';
          END IF;

          -- 2. Calculate Opening Balance (before p_start_date)
          SELECT 
              COALESCE(SUM(l.debit), 0),
              COALESCE(SUM(l.credit), 0)
          INTO v_opening_debit, v_opening_credit
          FROM journal_entry_lines l
          JOIN journal_entries e ON l.entry_id = e.id
          WHERE l.account_id = p_account_id
            AND e.entry_date < p_start_date
            AND (e.book = p_book OR e.book = 'BOTH');

          -- Determine opening balance based on account nature
          IF v_balance_type = 'No' THEN
              v_opening_balance := v_opening_debit - v_opening_credit;
          ELSIF v_balance_type = 'Co' THEN
              v_opening_balance := v_opening_credit - v_opening_debit;
          ELSE
              -- LuongTinh: default to Debit - Credit, can be negative
              v_opening_balance := v_opening_debit - v_opening_credit;
          END IF;

          -- 3. Return Opening Balance Row
          is_opening_balance := true;
          transaction_date := p_start_date - interval '1 day';
          doc_id := null;
          doc_type := null;
          description := 'Số dư đầu kỳ';
          cor_account_code := null;
          debit := 0;
          credit := 0;
          running_balance := v_opening_balance;
          RETURN NEXT;

          -- 4. Return Transactions within Period
          RETURN QUERY
          WITH lines AS (
              SELECT 
                  e.entry_date,
                  e.source_ref_id,
                  e.doc_type,
                  COALESCE(l.description, e.description) AS description,
                  l.debit,
                  l.credit,
                  -- Get opposing accounts
                  (
                      SELECT string_agg(DISTINCT c.account_code, ', ')
                      FROM journal_entry_lines opp
                      JOIN chart_of_accounts c ON opp.account_id = c.id
                      WHERE opp.entry_id = e.id
                        AND opp.id != l.id
                  ) AS cor_account_code
              FROM journal_entry_lines l
              JOIN journal_entries e ON l.entry_id = e.id
              WHERE l.account_id = p_account_id
                AND e.entry_date >= p_start_date
                AND e.entry_date <= p_end_date
                AND (e.book = p_book OR e.book = 'BOTH')
          ),
          calc AS (
              SELECT 
                  false AS is_opening_balance,
                  lines.entry_date AS transaction_date,
                  lines.source_ref_id AS doc_id,
                  lines.doc_type,
                  lines.description,
                  lines.cor_account_code,
                  lines.debit,
                  lines.credit,
                  CASE 
                      WHEN v_balance_type = 'No' THEN lines.debit - lines.credit
                      WHEN v_balance_type = 'Co' THEN lines.credit - lines.debit
                      ELSE lines.debit - lines.credit
                  END AS balance_change
              FROM lines
              ORDER BY lines.entry_date ASC
          )
          SELECT 
              calc.is_opening_balance,
              calc.transaction_date,
              calc.doc_id,
              calc.doc_type,
              calc.description,
              calc.cor_account_code,
              calc.debit,
              calc.credit,
              (v_opening_balance + SUM(calc.balance_change) OVER (ORDER BY calc.transaction_date ASC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW))::numeric AS running_balance
          FROM calc;

      END;
      $function$
