const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });

async function check() {
  await client.connect();
  const res = await client.query(`SELECT column_name, data_type FROM information_schema.columns WHERE table_name = 'promotions'`);
  console.log(res.rows);
  await client.end();
}
check();
