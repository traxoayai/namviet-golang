import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env' });
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  console.log("Querying get_sales_orders_view...");
  const { data, error } = await supabase.rpc('get_sales_orders_view', {
    p_order_type: 'B2B',
    p_page: 1,
    p_page_size: 1
  });
  
  if (error) {
    console.error("Error:", error);
    return;
  }
  
  console.log(JSON.stringify(data.data[0], null, 2));
}

test();
