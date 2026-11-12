// Chỉ đọc dữ liệu nghiệp vụ; đăng nhập/đăng xuất tài khoản đã có để kiểm tra.
const fs = require('fs');
const path = require('path');
const crypto = require('crypto');
const { pool } = require('/app/backend/config/database');

(async () => {
  if (process.env.DB_NAME !== 'quan_li_khai_tu') throw new Error('Sai CSDL dich.');
  const credentials = JSON.parse(fs.readFileSync(0, 'utf8').replace(/^\uFEFF/, ''));
  const checks = {};
  const [[admin]] = await pool.execute("SELECT Username,SHA2(PasswordHash,256) AS digest FROM App_User WHERE Id=1 AND Role='admin'");
  checks.adminPreserved = admin?.Username === 'okoklatoi' && admin.digest === '2374dbbe84a48078db72d851fd3cf5bd53dbafdf92d6c8a66f85a305d65366e3';
  const [[account]] = await pool.execute('SELECT u.Id,u.Username,u.Role,u.MaCanBo,cb.HoTen FROM App_User u JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Username=?', [credentials.username]);
  checks.staffBinding = account?.Role === 'staff' && account.MaCanBo === 'CB01';
  if (!checks.staffBinding) throw new Error('Tai khoan canbo01 khong lien ket CB01 hop le.');
  const [own] = await pool.execute(`SELECT h.SoGiayKhaiTu AS id,h.NgayDangKi AS registeredAt,h.TrangThaiHoSo AS status,
    g.CCCD_NgMat AS cccd,g.NgayGioMat AS deathAt,d.GioiTinh AS gender,d.TrangThai AS citizenStatus
    FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu
    JOIN Cong_Dan d ON d.CCCD=g.CCCD_NgMat WHERE h.MaCanBoTiepNhan=?`, [account.MaCanBo]);
  const [[other]] = await pool.execute(`SELECT h.SoGiayKhaiTu AS id,g.CCCD_NgMat AS cccd FROM Ho_So_Khai_Tu h
    JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE h.MaCanBoTiepNhan<>? LIMIT 1`, [account.MaCanBo]);
  const base = 'http://127.0.0.1:3000';
  async function call(url, cookie, body) {
    const response = await fetch(base+url, {method:body ? 'POST' : 'GET',headers:{...(cookie ? {Cookie:cookie} : {}),...(body ? {'Content-Type':'application/json'} : {})},body:body ? JSON.stringify(body) : undefined});
    return {status:response.status,data:await response.json(),cookie:response.headers.get('set-cookie')?.split(';')[0]};
  }
  const login = await call('/api/auth/login', null, credentials);
  checks.login = login.status===200 && login.data.user?.officerId==='CB01' && Boolean(login.cookie);
  if (!checks.login) throw new Error('Khong dang nhap duoc bang mat khau tam da tao; khong tu doi mat khau.');
  const cookie = login.cookie;
  const list = await call('/api/registrations?officerId=CB02', cookie);
  checks.exactOwnList = list.status===200 && JSON.stringify(list.data.map(row=>row.id).sort())===JSON.stringify(own.map(row=>row.id).sort()) && list.data.every(row=>row.officerId==='CB01');
  const dashboard = await call('/api/dashboard', cookie);
  checks.dashboard = dashboard.status===200 && dashboard.data.cards.total===own.length && dashboard.data.recent.every(row=>row.officerId==='CB01');
  const lookup = await call('/api/lookups', cookie);
  checks.onlyOwnOfficer = lookup.status===200 && lookup.data.officers.length===1 && lookup.data.officers[0].id==='CB01';
  checks.accountsDenied = (await call('/api/users', cookie)).status===403;
  checks.ownLookup = own.length>0 && (await call('/api/registrations/'+own[0].cccd, cookie)).status===200;
  checks.foreignLookupDenied = Boolean(other) && (await call('/api/registrations/'+other.cccd, cookie)).status===404;
  const foreignSearch = other && await call('/api/registrations?search='+encodeURIComponent(other.id), cookie);
  checks.foreignSearchHidden = foreignSearch?.status===200 && foreignSearch.data.length===0;
  const gender = await call('/api/reports/gender',cookie);
  checks.gender = gender.status===200 && gender.data.reduce((total,row)=>total+Number(row.value),0)===own.filter(row=>row.citizenStatus==='Đã mất').length;
  const areas = await call('/api/reports/areas?year=2026',cookie);
  checks.areas = areas.status===200 && areas.data.rows.reduce((total,row)=>total+Number(row.value),0)===own.filter(row=>row.registeredAt.startsWith('2026-') && row.status!=='Từ chối').length;
  const ages = await call('/api/reports/age-causes',cookie);
  checks.ages = ages.status===200 && ages.data.rows.reduce((total,row)=>total+Number(row.total),0)===own.filter(row=>row.status==='Đã duyệt').length;
  const years = await call('/api/reports/years',cookie);
  const expectedYears={}; for (const row of own) {const year=row.deathAt.slice(0,4);expectedYears[year]=(expectedYears[year]||0)+1;}
  checks.years = years.status===200 && JSON.stringify(Object.fromEntries(years.data.map(row=>[row.year,Number(row.value)])))===JSON.stringify(expectedYears);
  const hospitals = await call('/api/reports/hospitals',cookie);
  checks.hospitals = hospitals.status===200 && own.length<51 && hospitals.data.rows.length===0;
  const logout=await call('/api/auth/logout',cookie,{});
  checks.logout = logout.status===200 && logout.cookie==='session=';
  checks.anonymousDenied = (await call('/api/registrations')).status===401;
  const sources={};
  function hashFiles(folder) {
    for (const entry of fs.readdirSync(folder,{withFileTypes:true})) {
      const file=path.join(folder,entry.name);
      if(entry.isDirectory()) hashFiles(file);
      else sources[path.relative('/app',file)]=crypto.createHash('sha256').update(fs.readFileSync(file)).digest('hex');
    }
  }
  hashFiles('/app/backend');hashFiles('/app/public');
  process.stdout.write(JSON.stringify({checkedAt:new Date().toISOString(),username:account.Username,officerId:account.MaCanBo,name:account.HoTen,recordCount:own.length,checks,sources})+'\n');
  if(Object.values(checks).some(value=>!value)) process.exitCode=1;
})().catch(error=>{process.stderr.write(error.message+'\n');process.exitCode=1;}).finally(()=>pool.end());
