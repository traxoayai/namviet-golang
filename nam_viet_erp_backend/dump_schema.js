const { Client } = require('pg');
const fs = require('fs');

const connectionString = "postgresql://postgres.iudkexocalqdhxuyjacu:Longlong123%40a@aws-1-ap-southeast-1.pooler.supabase.com:6543/postgres";

async function main() {
    const client = new Client({
        connectionString,
        ssl: { rejectUnauthorized: false }
    });
    
    await client.connect();
    
    // Get all tables in public schema
    const tablesQuery = `
        SELECT c.oid, c.relname as table_name, obj_description(c.oid) as table_description
        FROM pg_class c
        JOIN pg_namespace n ON n.oid = c.relnamespace
        WHERE c.relkind = 'r' AND n.nspname = 'public'
        ORDER BY c.relname;
    `;
    
    const tablesRes = await client.query(tablesQuery);
    let markdown = '';
    
    for (const table of tablesRes.rows) {
        let tableDesc = table.table_description ? ` <== ${table.table_description}>` : '';
        markdown += `### Table: ${table.table_name}${tableDesc}\n`;
        
        const columnsQuery = `
            SELECT 
                a.attname as column_name,
                pg_catalog.format_type(a.atttypid, a.atttypmod) as data_type,
                NOT a.attnotnull as is_nullable,
                pg_get_expr(ad.adbin, ad.adrelid) as column_default,
                col_description(a.attrelid, a.attnum) as column_description
            FROM pg_attribute a
            LEFT JOIN pg_attrdef ad ON a.attrelid = ad.adrelid AND a.attnum = ad.adnum
            WHERE a.attrelid = $1 AND a.attnum > 0 AND NOT a.attisdropped
            ORDER BY a.attnum;
        `;
        
        const colsRes = await client.query(columnsQuery, [table.oid]);
        
        for (const col of colsRes.rows) {
            let nullable = col.is_nullable ? 'YES' : 'NO';
            let defaultStr = col.column_default ? ` DEFAULT ${col.column_default}` : '';
            let descStr = col.column_description ? ` <== ${col.column_description}>` : '';
            markdown += `- **${col.column_name}**: ${col.data_type} (Nullable: ${nullable})${defaultStr}${descStr}\n`;
        }
        
        markdown += `\n`;
    }
    
    fs.writeFileSync('D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\database_schema.md', markdown);
    
    // Export RPCs
    const rpcQuery = `
        SELECT p.oid, p.proname as function_name
        FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname = 'public' AND p.prokind IN ('f', 'p')
    `;
    const rpcRes = await client.query(rpcQuery);
    
    if (!fs.existsSync('D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\functions_sql')) {
        fs.mkdirSync('D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\functions_sql');
    }
    
    for (const rpc of rpcRes.rows) {
        try {
            const defRes = await client.query(`SELECT pg_get_functiondef($1) as function_def`, [rpc.oid]);
            fs.writeFileSync(`D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\functions_sql\\\\${rpc.function_name}.sql`, defRes.rows[0].function_def);
        } catch (err) {
            console.warn(`Skipping function ${rpc.function_name}:`, err.message);
        }
    }

    // Export Triggers
    const triggerQuery = `
        SELECT tgname, pg_get_triggerdef(oid) as trigger_def
        FROM pg_trigger
        WHERE NOT tgisinternal AND tgrelid IN (SELECT oid FROM pg_class WHERE relnamespace = (SELECT oid FROM pg_namespace WHERE nspname = 'public'));
    `;
    const triggerRes = await client.query(triggerQuery);
    
    if (!fs.existsSync('D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\triggers_sql')) {
        fs.mkdirSync('D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\triggers_sql');
    }
    
    for (const trigger of triggerRes.rows) {
        fs.writeFileSync(`D:\\\\29.NamVietErp-V3\\\\nam_viet_erp\\\\supabase\\\\triggers_sql\\\\${trigger.tgname}.sql`, trigger.trigger_def);
    }
    
    await client.end();
    console.log("Dumped schema successfully.");
}

main().catch(console.error);
