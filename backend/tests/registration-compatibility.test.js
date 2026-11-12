const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const { validateRegistration } = require('../modules/registrations/validation');
const { normalizeStatus } = require('../modules/registrations/status');
const { validateCatalog } = require('../modules/catalogs/validation');

function payload() {
  return {
    deceased: { cccd:'001234567890',name:'Người thử',birthDate:'1940-01-01',gender:'Nam',hometown:'Hà Nội' },
    applicant: { cccd:'001234567891',name:'Người đăng ký thử',birthDate:'1980-01-01',gender:'Nữ',hometown:'Hà Nội' },
    certificate: { id:'GBT-TEST',issuedAt:'2026-11-09',deathAt:'2026-11-08T12:34:56',placeDetail:'Nơi thử',causeId:'NN-TEST',wardId:'XA-TEST',hospitalId:'CS-TEST' },
    registration: { id:'HS-TEST',registeredAt:'2026-11-09',relation:'Người thân',officerId:'CB-TEST' }
  };
}

function loadRoutes(relativeFile, pool) {
  const filename = path.join(__dirname, '..', relativeFile);
  const localRequire = createRequire(filename);
  const routes = [];
  const router = Object.fromEntries(['get','post','patch','delete','use'].map(method => [method,
    (routePath, ...handlers) => routes.push({ method, path: routePath, handlers })]));
  const module = { exports:{} };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), {
    module, exports:module.exports,
    require(name) {
      if (name === 'express') return { Router:() => router };
      if (name.endsWith('/config/database')) return { pool };
      if (name.endsWith('/middleware/auth')) return { adminOnly:(_req,_res,next) => next() };
      return localRequire(name);
    }
  }, { filename });
  return routes;
}

async function invoke(route, request) {
  request = { user: { role: 'admin' }, ...request };
  const response = { statusCode:200,body:undefined,status(code) { this.statusCode = code; return this; },json(body) { this.body = JSON.parse(JSON.stringify(body)); return this; } };
  let error;
  await route.handlers.at(-1)(request, response, nextError => { error = nextError; });
  return { response, error };
}

function connection(existing = { CCCD_NgMat:'001234567890' }) {
  const calls = [];
  return {
    calls,
    async execute(sql, params = []) { calls.push({sql,params}); return (sql.startsWith('SELECT g.CCCD_NgMat') || sql.startsWith('SELECT h.SoGiayBaoTu')) ? [[existing].filter(Boolean)] : [{affectedRows:1}]; },
    async beginTransaction() { calls.push({sql:'BEGIN'}); },
    async commit() { calls.push({sql:'COMMIT'}); },
    async rollback() { calls.push({sql:'ROLLBACK'}); },
    release() { calls.push({sql:'RELEASE'}); }
  };
}

test('hồ sơ theo schema nguồn: trường tùy chọn, giới hạn ký tự, TEXT và trạng thái mặc định', () => {
  const body = payload();
  body.deceased.name = 'Đ'.repeat(100);
  body.deceased.hometown = 'Q'.repeat(255);
  body.certificate.placeDetail = 'N'.repeat(255);
  body.certificate.causeDescription = 'Mô tả '.repeat(1000);
  body.registration.id = 'H'.repeat(20);
  const result = validateRegistration(body);
  assert.equal(result.registration.status,'Chờ xử lý');
  assert.equal(result.deceased.ethnicity,'Kinh');
  assert.equal(result.deceased.phone,'');
  assert.equal(result.applicant.phone,'');
  assert.equal(result.certificate.deathAt,'2026-11-08 12:34:56');
  assert.ok(result.certificate.causeDescription.length > 100);
  const optional = payload(); delete optional.deceased.hometown; delete optional.applicant.hometown; delete optional.certificate.placeDetail;
  assert.equal(validateRegistration(optional).deceased.hometown,'');
  assert.equal(validateRegistration(optional).certificate.placeDetail,'');
  for (const mutate of [
    body => { body.deceased.name = 'A'.repeat(101); },
    body => { body.deceased.hometown = 'A'.repeat(256); },
    body => { body.deceased.ethnicity = 'A'.repeat(51); },
    body => { body.deceased.phone = '0'.repeat(16); },
    body => { body.deceased.gender = 'N'; },
    body => { body.deceased.cccd = '123'; },
    body => { body.deceased.name = 123; },
    body => { body.certificate.id = 'A'.repeat(21); },
    body => { body.registration.id = 'A'.repeat(21); },
    body => { body.certificate.causeId = 'A'.repeat(21); },
    body => { body.certificate.placeDetail = 'A'.repeat(256); },
    body => { body.certificate.causeDescription = 'Đ'.repeat(32768); },
    body => { body.registration.relation = 'A'.repeat(51); },
    body => { body.registration.status = 'Tự duyệt'; }
  ]) {
    const invalid = payload(); mutate(invalid);
    assert.throws(() => validateRegistration(invalid), {statusCode:400});
  }
});

test('an táng phát hiện dữ liệu dở dang kể cả thiếu mã và bắt buộc ngày hợp lệ', () => {
  for (const burial of [{form:'Hỏa táng'},{id:'AT-TEST',form:'Hỏa táng',cemetery:'Đài thử'},{id:'AT-TEST',form:'Hỏa táng',cemetery:'Đài thử',date:'2026-02-30'},{id:'AT-TEST',form:'Hỏa táng',cemetery:'Đài thử',date:'2026-11-07'}]) {
    assert.throws(() => validateRegistration({...payload(),burial}),{statusCode:400});
  }
  const burial = {id:'A'.repeat(30),form:'Hỏa táng',cemetery:'N'.repeat(150),date:'2026-11-09'};
  assert.deepEqual(validateRegistration({...payload(),burial}).burial,burial);
  assert.throws(() => validateRegistration({...payload(),burial:{...burial,cemetery:'N'.repeat(151)}}),{statusCode:400});
  assert.throws(() => validateRegistration({...payload(),burial:{...burial,form:'Khác'}}),{statusCode:400});
  assert.equal(validateRegistration({...payload(),burial:{id:'',date:''}}).burial,null);
});

test('CREATE chuẩn hóa trạng thái cũ, không INSERT IGNORE/ghi đè công dân và chỉ đánh dấu mất với hồ sơ hợp lệ', async () => {
  for (const [inputStatus,expected,deadUpdates] of [[undefined,'Chờ xử lý',1],['Đã hoàn tất','Đã duyệt',1],['Đang xử lý','Chờ xử lý',1],['Từ chối','Từ chối',0]]) {
    const conn = connection();
    const routes = loadRoutes('modules/registrations/index.js',{getConnection:async () => conn});
    const body = payload(); if (inputStatus) body.registration.status = inputStatus;
    const result = await invoke(routes.find(route => route.method === 'post'),{body});
    assert.equal(result.error,undefined);
    assert.equal(result.response.statusCode,201);
    assert.equal(result.response.body.status,expected);
    assert.match(conn.calls[0].sql,/STRICT_TRANS_TABLES/);
    const citizens = conn.calls.filter(call => call.sql.startsWith('INSERT INTO Cong_Dan'));
    assert.equal(citizens.length,2);
    for (const call of citizens) {
      assert.doesNotMatch(call.sql,/INSERT IGNORE/);
      assert.match(call.sql,/'Còn sống'/);
      assert.match(call.sql,/ON DUPLICATE KEY UPDATE CCCD=Cong_Dan.CCCD\s*$/);
      assert.equal(call.params[5],'Kinh');
      assert.equal(call.params[6],'');
    }
    const certificateInsert = conn.calls.find(call => call.sql.startsWith('INSERT INTO Giay_Bao_Tu'));
    assert.match(certificateInsert.sql,/CCCD_NgMat/);
    assert.equal(certificateInsert.params[5],body.deceased.cccd);
    assert.doesNotMatch(conn.calls.find(call => call.sql.startsWith('INSERT INTO Ho_So_Khai_Tu')).sql,/CCCD_NgMat/);
    assert.equal(conn.calls.find(call => call.sql.startsWith('INSERT INTO Ho_So_Khai_Tu')).params[3],expected);
    assert.equal(conn.calls.filter(call => call.sql.startsWith('UPDATE Cong_Dan')).length,deadUpdates);
    assert.ok(conn.calls.some(call => call.sql === 'COMMIT'));
    assert.equal(conn.calls.at(-1).sql,'RELEASE');
  }
});

test('PATCH trạng thái giao dịch đồng bộ công dân, không đổi về Còn sống và rollback khi lỗi', async () => {
  for (const [inputStatus,expected,deadUpdates] of [['Đã tiếp nhận','Chờ xử lý',1],['Chờ duyệt','Chờ xử lý',1],['Đã hoàn tất','Đã duyệt',1],['Từ chối','Từ chối',0]]) {
    const conn = connection();
    const routes = loadRoutes('modules/registrations/index.js',{getConnection:async () => conn});
    const patch = routes.find(route => route.method === 'patch');
    const result = await invoke(patch,{params:{id:'HS-TEST'},body:{status:inputStatus}});
    assert.equal(result.error,undefined);
    assert.equal(result.response.body.status,expected);
    assert.equal(conn.calls.find(call => call.sql.startsWith('UPDATE Ho_So')).params[0],expected);
    assert.equal(conn.calls.filter(call => call.sql.startsWith('UPDATE Cong_Dan')).length,deadUpdates);
    assert.ok(!conn.calls.some(call => /SET TrangThai='Còn sống'/.test(call.sql)));
  }
  const missingConnection = connection(null);
  let routes = loadRoutes('modules/registrations/index.js',{getConnection:async () => missingConnection});
  let result = await invoke(routes.find(route => route.method === 'patch'),{params:{id:'UNKNOWN'},body:{status:'Đã duyệt'}});
  assert.equal(result.response.statusCode,404);
  assert.ok(missingConnection.calls.some(call => call.sql === 'ROLLBACK'));
  assert.ok(!missingConnection.calls.some(call => call.sql.startsWith('UPDATE ')));
  const failingConnection = connection();
  const originalExecute = failingConnection.execute;
  failingConnection.execute = async function(sql,params) { if (sql.startsWith('UPDATE Cong_Dan')) throw new Error('Lỗi thử nghiệm'); return originalExecute.call(this,sql,params); };
  routes = loadRoutes('modules/registrations/index.js',{getConnection:async () => failingConnection});
  result = await invoke(routes.find(route => route.method === 'patch'),{params:{id:'HS-TEST'},body:{status:'Đã duyệt'}});
  assert.match(result.error.message,/Lỗi thử nghiệm/);
  assert.ok(failingConnection.calls.some(call => call.sql === 'ROLLBACK'));
  assert.ok(!failingConnection.calls.some(call => call.sql === 'COMMIT'));
});

test('bộ lọc/API và dashboard nhận đồng thời trạng thái chuẩn và dữ liệu cũ', async () => {
  assert.equal(normalizeStatus('Đã hoàn tất'),'Đã duyệt');
  for (const status of ['Đã tiếp nhận','Đang xử lý','Chờ duyệt','Chờ xử lý']) assert.equal(normalizeStatus(status),'Chờ xử lý');
  const calls = [];
  const routes = loadRoutes('modules/registrations/index.js',{async execute(sql,params) { calls.push({sql,params}); return [[{id:'HS-TEST',status:'Đã hoàn tất'}]]; }});
  const list = routes.find(route => route.method === 'get' && route.path === '/');
  const result = await invoke(list,{query:{status:'Đang xử lý'}});
  assert.equal(result.response.body[0].status,'Đã duyệt');
  assert.equal(calls[0].params[0],'Chờ xử lý');
  assert.match(calls[0].sql,/CASE/);
  assert.match(calls[0].sql,/Đã tiếp nhận/);
  const dashboardCalls = [];
  const dashboard = loadRoutes('modules/dashboard/index.js',{async execute(sql) { dashboardCalls.push(sql); return dashboardCalls.length === 1 ? [[{total:1,completed:1,active:0,thisMonth:1}]] : dashboardCalls.length === 4 ? [[{id:'HS-TEST',status:'Đã hoàn tất'}]] : [[]]; }});
  const report = await invoke(dashboard[0],{});
  assert.match(dashboardCalls[0],/'Đã duyệt', 'Đã hoàn tất'/);
  assert.match(dashboardCalls[0],/'Chờ xử lý', 'Chờ duyệt', 'Đã tiếp nhận', 'Đang xử lý'/);
  assert.equal(report.response.body.recent[0].status,'Đã duyệt');
});

test('danh mục dùng đúng giới hạn từng cột, CCCD cán bộ, điện thoại bắt buộc và cấp UBND', () => {
  const hospital = validateCatalog('hospital',{id:'C'.repeat(20),name:'N'.repeat(150),address:'A'.repeat(255),phone:'0123456789'});
  assert.equal(hospital.phone,'0123456789');
  assert.throws(() => validateCatalog('hospital',{id:'C',name:'N',address:'A'}),{statusCode:400});
  for (const values of [{id:'C'.repeat(21),name:'N',address:'A'},{id:'C',name:'N'.repeat(151),address:'A'},{id:'C',name:'N',address:'A'.repeat(256)},{id:'C',name:'N',address:'A',phone:'0'.repeat(16)}]) {
    assert.throws(() => validateCatalog('hospital',values),{statusCode:400});
  }
  const officer = {id:'CB',identity:'001234567890',name:'N'.repeat(100),role:'R'.repeat(100),officeId:'UBND',phone:'0123456789'};
  assert.equal(validateCatalog('officer',officer).phone,'0123456789');
  assert.throws(() => validateCatalog('officer',{...officer,identity:'123'}),{statusCode:400});
  assert.throws(() => validateCatalog('ward',{id:'X',name:'N'.repeat(101),province:'Hà Nội',unitType:'Xã'}),{statusCode:400});
  assert.throws(() => validateCatalog('office',{id:'U',name:'N',address:'A',phone:'0123456789',level:'L'.repeat(51)}),{statusCode:400});
  assert.throws(() => validateCatalog('office',{id:'U',name:'N',address:'A',phone:'0123456789',level:'Huyện'}),{statusCode:400});
  assert.equal(validateCatalog('office',{id:'U',name:'N',address:'A',phone:'0123456789',level:'Phường'}).level,'Phường');
  assert.deepEqual(validateCatalog('ward',{id:'XP',name:'Xã mới'}),{id:'XP',name:'Xã mới'});
});

test('tra cứu và xóa lấy người mất qua giấy báo tử, xóa hồ sơ không xóa công dân', async () => {
  const { registrationQuery } = require('../modules/registrations/queries');
  assert.match(registrationQuery,/d\.CCCD = g\.CCCD_NgMat/);
  assert.doesNotMatch(registrationQuery,/h\.CCCD_NgMat/);
  const conn = connection({SoGiayBaoTu:'GBT-TEST',CCCD_NgMat:'001234567890',CCCD_NgKhaiTu:'001234567891'});
  const routes = loadRoutes('modules/registrations/index.js',{getConnection:async()=>conn});
  const result = await invoke(routes.find(route=>route.method==='delete'),{params:{id:'HS-TEST'}});
  assert.equal(result.error,undefined);
  assert.equal(result.response.body.deletedCitizens,0);
  const select = conn.calls.find(call=>call.sql.startsWith('SELECT '));
  assert.match(select.sql,/g\.CCCD_NgMat/);
  assert.doesNotMatch(select.sql,/h\.CCCD_NgMat/);
  assert.deepEqual(conn.calls.filter(call=>call.sql.startsWith('DELETE ')).map(call=>call.sql.split(' ')[2]),['An_Tang','Ho_So_Khai_Tu','Giay_Bao_Tu']);
  assert.ok(!conn.calls.some(call=>call.sql.startsWith('DELETE FROM Cong_Dan')));
  assert.ok(conn.calls.some(call=>call.sql==='COMMIT'));
});

test('nguồn đếm của từng báo cáo khớp truy_van.sql: công dân đã mất, hồ sơ đã duyệt và mọi giấy báo tử', async () => {
  const { genderQuery,yearQuery,areaQuery,ageCauseQuery,hospitalQuery } = require('../modules/reports/queries');
  assert.match(genderQuery,/FROM Cong_Dan c WHERE c\.TrangThai='Đã mất'/);
  assert.doesNotMatch(genderQuery,/Ho_So_Khai_Tu/);
  assert.match(yearQuery,/FROM Giay_Bao_Tu/);
  assert.doesNotMatch(yearQuery,/Ho_So_Khai_Tu|TrangThai/);
  assert.match(areaQuery,/COUNT\(h\.SoGiayKhaiTu\)/);
  assert.match(areaQuery,/LEFT JOIN Ho_So_Khai_Tu/);
  assert.match(areaQuery,/h\.TrangThaiHoSo <> 'Từ chối'/);
  assert.match(ageCauseQuery,/WHERE h\.TrangThaiHoSo='Đã duyệt'/);
  assert.match(ageCauseQuery,/d\.CCCD=g\.CCCD_NgMat/);
  assert.doesNotMatch(ageCauseQuery,/h\.CCCD_NgMat/);
  const ageRoutes = loadRoutes('modules/reports/age-causes/index.js',{async execute(){return [[
    {ageGroup:'Dưới 18',cause:'A',value:5},{ageGroup:'18–60',cause:'B',value:38},
    {ageGroup:'Trên 60',cause:'C',value:19},{ageGroup:'Trên 60',cause:'D',value:19}
  ]];}});
  const ages = await invoke(ageRoutes[0],{});
  assert.equal(ages.response.body.rows.reduce((sum,row)=>sum+row.total,0),81);
  assert.equal(ages.response.body.rows[2].commonCauses.length,2);
  assert.match(hospitalQuery,/c\.TenCSYT/);
  assert.match(hospitalQuery,/c\.DiaChi/);
  assert.match(hospitalQuery,/HAVING COUNT\(\*\) > 50/);
  assert.match(hospitalQuery,/AS estimatedDeaths/);
  assert.match(hospitalQuery,/AS estimatedPercent/);
  let bound;
  const hospitalRoutes = loadRoutes('modules/reports/hospitals/index.js',{async execute(_sql,params){bound=params;return [[{id:'CS01',name:'Cơ sở thử',value:52,estimatedDeaths:20,estimatedPercent:'38.46'}]];}});
  const hospitals = await invoke(hospitalRoutes[0],{});
  assert.equal(hospitals.response.body.rows[0].value,52);
  assert.equal(hospitals.response.body.rows[0].estimatedDeaths,20);
  assert.equal(hospitals.response.body.rows[0].estimatedPercent,'38.46');
  assert.deepEqual(Array.from(bound),[hospitals.response.body.period.start,hospitals.response.body.period.end]);
});

test('dữ liệu hồ sơ hoặc danh mục quá dài bị chặn trước khi mở kết nối ghi', async () => {
  let connections = 0;
  const pool = { getConnection() { connections += 1; throw new Error('Không được truy cập DB'); } };
  const registrationRoutes = loadRoutes('modules/registrations/index.js',pool);
  const body = payload(); body.deceased.phone = '0'.repeat(16);
  let result = await invoke(registrationRoutes.find(route => route.method === 'post'),{body});
  assert.equal(result.error.statusCode,400);
  const catalogRoutes = loadRoutes('modules/catalogs/index.js',pool);
  result = await invoke(catalogRoutes.find(route => route.method === 'post'),{params:{type:'cause'},body:{id:'N'.repeat(21),name:'Thử'}});
  assert.equal(result.error.statusCode,400);
  assert.equal(connections,0);
});
