import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
dotenv.config({ path: '.env' });
dotenv.config({ path: '.env.local' });

const supabaseUrl = process.env.VITE_SUPABASE_URL || '';
const supabaseKey = process.env.VITE_SUPABASE_ANON_KEY || '';

const supabase = createClient(supabaseUrl, supabaseKey);

async function test() {
  console.log("Querying finance_transactions...");
  const { data, error } = await supabase
    .from('finance_transactions')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(5);
  
  if (error) {
    console.error("Error:", error);
    return;
  }
  
  console.log(JSON.stringify(data.map(t => ({
    id: t.id,
    code: t.code,
    partner_type: t.partner_type,
    partner_id: t.partner_id,
    partner_name_cache: t.partner_name_cache,
    description: t.description
  })), null, 2));
}

test();
