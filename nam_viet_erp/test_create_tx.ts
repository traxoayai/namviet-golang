import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env' });
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';
const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  const payload = {
    p_flow: "in",
    p_business_type: "trade",
    p_fund_id: 1,
    p_amount: 100000,
    p_category_id: null,
    p_transaction_date: new Date().toISOString(),
    p_description: "Thu tiền đơn hàng test",
    p_status: "pending",
    p_partner_type: "other",
    p_partner_name: "Tên B2B Test"
  };

  const { data, error } = await supabase.rpc("create_finance_transaction", payload);
  if (error) {
    console.error("Error creating tx:", error);
    return;
  }
  console.log("Created tx ID:", data);

  const { data: getTxs, error: getErr } = await supabase.rpc("get_transactions", {
    p_page: 1,
    p_page_size: 5,
    p_search: null,
    p_flow: "in",
    p_status: null,
    p_date_from: null,
    p_date_to: null,
    p_creator_id: null
  });
  console.log("Tx list:", JSON.stringify(getTxs, null, 2));
}

test();
