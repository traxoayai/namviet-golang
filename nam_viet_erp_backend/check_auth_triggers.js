const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });
client.connect()
.then(() => client.query(`SELECT tgname, pg_get_triggerdef(oid) FROM pg_trigger WHERE tgrelid = 'auth.users'::regclass;`))
.then(res => { console.log(res.rows); client.end(); })
