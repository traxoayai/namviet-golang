const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });

async function check() {
  await client.connect();
  const res = await client.query(`SELECT view_definition FROM information_schema.views WHERE table_name = 'b2b_customer_debt_view'`);
  console.log("View definition:", res.rows[0]?.view_definition);
  await client.end();
}
check();
