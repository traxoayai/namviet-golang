const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });
client.connect().then(() => client.query(`SELECT r.name, COUNT(ur.user_id) as count FROM user_roles ur JOIN role_permissions rp ON ur.role_id = rp.role_id JOIN roles r ON r.id = ur.role_id WHERE rp.permission_key IN ('portal.manage', 'admin-all') GROUP BY r.name;`)).then(res => { console.log("USER_ROLES BREAKDOWN:", res.rows); client.end(); })
