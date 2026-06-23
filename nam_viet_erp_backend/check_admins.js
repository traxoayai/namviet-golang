const { Client } = require("pg");
const client = new Client({
  connectionString:
    "postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres",
  ssl: { rejectUnauthorized: false },
});
client
  .connect()
  .then(() => client.query(`SELECT id, name FROM roles;`))
  .then((res) => {
    console.log("ROLES:", res.rows);
    return client.query(
      `SELECT u.email, r.name, ur.created_at FROM user_roles ur JOIN auth.users u ON u.id = ur.user_id JOIN roles r ON r.id = ur.role_id WHERE r.name = 'Admin' ORDER BY ur.created_at DESC LIMIT 5;`,
    );
  })
  .then((res) => {
    console.log("LATEST ADMINS:", res.rows);
    return client.query(
      `SELECT u.email, pu.customer_b2b_id FROM auth.users u JOIN portal_users pu ON u.id = pu.auth_user_id JOIN user_roles ur ON ur.user_id = u.id JOIN roles r ON r.id = ur.role_id WHERE r.name = 'Admin' LIMIT 10;`,
    );
  })
  .then((res) => {
    console.log("PORTAL USERS AS ADMIN:", res.rows);
    client.end();
  });
