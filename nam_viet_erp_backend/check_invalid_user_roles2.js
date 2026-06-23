const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });
client.connect()
.then(() => client.query(`SELECT ur.user_id, u.email, r.name as role FROM user_roles ur JOIN auth.users u ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id WHERE ur.user_id IN (SELECT auth_user_id FROM portal_users) AND r.name = 'Admin';`))
.then(res => { 
    console.log('PORTAL USERS AS ADMIN COUNT:', res.rows.length); 
    return client.query(`SELECT COUNT(*) FROM user_roles WHERE role_id = (SELECT id FROM roles WHERE name = 'Admin');`);
})
.then(res => {
    console.log('TOTAL ADMINS IN USER_ROLES:', res.rows);
    return client.query(`SELECT ur.user_id, u.email FROM user_roles ur JOIN auth.users u ON ur.user_id = u.id WHERE ur.role_id = (SELECT id FROM roles WHERE name = 'Admin') AND ur.user_id NOT IN (SELECT id FROM public.users);`);
})
.then(res => {
    console.log('ADMINS NOT IN PUBLIC.USERS:', res.rows.length);
    client.end(); 
})
