const { Client } = require('pg');
const fs = require('fs');
const client = new Client({ connectionString: 'postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres', ssl: { rejectUnauthorized: false } });

async function run() {
    await client.connect();
    const sql = fs.readFileSync('D:/29.NamVietErp-V3/nam_viet_erp/supabase/fix_invalid_admin_roles.sql', 'utf8');
    const result = await client.query(sql);
    console.log(`DELETED ${result.rowCount} invalid records from user_roles.`);
    
    const remainingAdmins = await client.query(`SELECT COUNT(*) as cnt FROM user_roles ur JOIN roles r ON ur.role_id = r.id WHERE r.name = 'Admin'`);
    console.log(`Remaining Admins: ${remainingAdmins.rows[0].cnt}`);
    
    await client.end();
}
run().catch(err => console.error(err));
