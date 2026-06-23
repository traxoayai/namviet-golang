const { Client } = require('pg');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });
client.connect()
.then(() => client.query(`SELECT ur.created_at FROM user_roles ur JOIN auth.users u ON ur.user_id = u.id WHERE ur.role_id = (SELECT id FROM roles WHERE name = 'Admin') AND ur.user_id NOT IN (SELECT id FROM public.users);`))
.then(res => {
    let dates = {};
    for (let r of res.rows) {
        let d = new Date(r.created_at).toISOString().substring(0, 10);
        dates[d] = (dates[d] || 0) + 1;
    }
    console.log('INVALID ADMINS CREATION DATES:', dates);
    client.end(); 
})
