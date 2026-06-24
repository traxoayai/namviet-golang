const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });

async function check() {
  await client.connect();
  const res1 = await client.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'products'`);
  console.log("products:", res1.rows);
  const res2 = await client.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'vendor_product_mappings'`);
  console.log("vendor_product_mappings:", res2.rows);
  await client.end();
}
check();
