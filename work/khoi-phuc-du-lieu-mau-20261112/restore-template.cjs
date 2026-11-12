// Local, explicit opt-in. No schema changes or foreign-key disabling.
const crypto = require('crypto');
const { pool } = require('/app/backend/config/database');
const { strictWrites } = require('/app/backend/utils/validation');
const payload = __SEED_PAYLOAD__;
const keys = {Nguyen_Nhan:'MaNguyenNhan',CSYT:'MaCSYT',Noi_Mat:'MaXaPhuong',UBND:'MaUBND',Can_Bo:'MaCanBo',Cong_Dan:'CCCD',Giay_Bao_Tu:'SoGiayBaoTu',Ho_So_Khai_Tu:'SoGiayKhaiTu',An_Tang:'MaAnTang'};
const catalogs = ['Nguyen_Nhan','CSYT','Noi_Mat','UBND','Can_Bo'];
const peopleAndRecords = ['Cong_Dan','Giay_Bao_Tu','Ho_So_Khai_Tu','An_Tang'];
const hash = value => crypto.createHash('sha256').update(JSON.stringify(value)).digest('hex');
const ident = value => {if(!/^[A-Za-z_][A-Za-z0-9_]*$/.test(value)) throw new Error('Invalid SQL identifier');return '`'+value+'`';};

(async () => {
  if(process.env.DB_NAME!=='quan_li_khai_tu') throw new Error('Unexpected target database');
  if(JSON.stringify(Object.keys(payload.tables).sort())!==JSON.stringify(Object.keys(keys).sort())) throw new Error('Unexpected sample tables');
  const conn=await pool.getConnection();let transaction=false;
  try {
    await strictWrites(conn);
    await conn.query("SET SESSION time_zone='+07:00'");
    for(const [table,item] of Object.entries(payload.tables)) {
      const [columns]=await conn.execute('SELECT COLUMN_NAME FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=?',[table]);
      if(JSON.stringify(columns.map(row=>row.COLUMN_NAME).sort())!==JSON.stringify([...item.columns].sort())) throw new Error('Schema mismatch: '+table);
    }
    await conn.beginTransaction();transaction=true;
    const [accounts]=await conn.query('SELECT * FROM App_User ORDER BY Id FOR UPDATE');
    const sourceOfficerIds=new Set(payload.tables.Can_Bo.rows.map(row=>row.MaCanBo));
    if(accounts.some(user=>user.Role==='staff'&&!sourceOfficerIds.has(user.MaCanBo))) throw new Error('A staff account is linked to an officer outside the source sample; no automatic reassignment');
    const before={};
    for(const table of Object.keys(keys)) {const [[row]]=await conn.query('SELECT COUNT(*) AS total FROM '+ident(table));before[table]=Number(row.total);}
    if(!process.argv.includes('--apply')) {
      await conn.rollback();transaction=false;
      process.stdout.write(JSON.stringify({ok:true,dryRun:true,before,expected:Object.fromEntries(Object.entries(payload.tables).map(([table,item])=>[table,item.rows.length])),accountCount:accounts.length})+'\n');return;
    }
    for(const table of ['An_Tang','Ho_So_Khai_Tu','Giay_Bao_Tu','Cong_Dan']) await conn.query('DELETE FROM '+ident(table));
    if(process.argv.includes('--probe-rollback')) throw new Error('Rollback probe');
    async function insertRows(table, upsert) {
      const item=payload.tables[table];const columns=item.columns;
      const updates=columns.filter(column=>column!==keys[table]).map(column=>ident(column)+'=VALUES('+ident(column)+')').join(',');
      const sql='INSERT INTO '+ident(table)+' ('+columns.map(ident).join(',')+') VALUES ('+columns.map(()=>'?').join(',')+')'+(upsert?' ON DUPLICATE KEY UPDATE '+updates:'');
      for(const row of item.rows) await conn.execute(sql,columns.map(column=>row[column]));
    }
    // Preserve the officer rows referenced by App_User while restoring their sample fields.
    for(const table of catalogs) await insertRows(table,true);
    for(const table of [...catalogs].reverse()) {
      const ids=payload.tables[table].rows.map(row=>row[keys[table]]);
      await conn.execute('DELETE FROM '+ident(table)+' WHERE '+ident(keys[table])+' NOT IN ('+ids.map(()=>'?').join(',')+')',ids);
    }
    for(const table of peopleAndRecords) await insertRows(table,false);
    const after={};
    for(const [table,item] of Object.entries(payload.tables)) {
      const [rows]=await conn.query('SELECT '+item.columns.map(ident).join(',')+' FROM '+ident(table)+' ORDER BY '+ident(keys[table]));
      const expected=item.rows.map(row=>item.columns.map(column=>row[column])).sort((a,b)=>a[item.columns.indexOf(keys[table])]<b[item.columns.indexOf(keys[table])]?-1:1);
      const actual=rows.map(row=>item.columns.map(column=>row[column]));
      if(hash(actual)!==hash(expected)) throw new Error('Sample verification mismatch: '+table);
      after[table]={rows:actual.length,sha256:hash(actual),matchesSource:true};
    }
    const [accountsAfter]=await conn.query('SELECT * FROM App_User ORDER BY Id');
    if(hash(accountsAfter)!==hash(accounts)) throw new Error('Account preservation check failed');
    await conn.commit();transaction=false;
    process.stdout.write(JSON.stringify({ok:true,sourceSha256:payload.sourceSha256,before,after,accountsPreserved:true,accountCount:accounts.length,totalRows:Object.values(after).reduce((sum,item)=>sum+item.rows,0)})+'\n');
  } catch(error) {
    if(transaction) await conn.rollback();
    process.stdout.write(JSON.stringify({ok:false,rolledBack:transaction,error:error.code||error.message})+'\n');process.exitCode=1;
  } finally {conn.release();}
})().catch(error=>{process.stdout.write(JSON.stringify({ok:false,error:error.code||error.message})+'\n');process.exitCode=1;}).finally(()=>pool.end());
