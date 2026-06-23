const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });
client.connect()
.then(() => client.query(`SELECT COUNT(*) FROM user_roles ur JOIN portal_users pu ON ur.user_id = pu.auth_user_id;`))
.then(res => { 
    console.log('PORTAL USERS WITH USER_ROLES:', res.rows); 
    return client.query(`SELECT COUNT(*) FROM user_roles ur WHERE ur.created_at >= '2026-06-16T06:52:00Z' AND ur.created_at <= '2026-06-16T06:53:00Z';`);
})
.then(res => { 
    console.log('USER_ROLES CREATED AT BATCH TIME:', res.rows); 
    client.end(); 
})
