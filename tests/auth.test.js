const assert = require('node:assert/strict');
const { after, beforeEach, test } = require('node:test');
const { IncomingMessage, ServerResponse } = require('node:http');
const { Duplex } = require('node:stream');
const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');

// Exercise the real HTTP app without opening a connection to an existing database.
process.env.JWT_SECRET = 'isolated-auth-tests-secret-with-at-least-32-characters';
process.env.COOKIE_SECURE = 'false';
process.env.ALLOW_LOCAL_PASSWORD_RESET = 'false';
const metadataDirectory = fs.mkdtempSync(path.join(os.tmpdir(), 'khai-tu-auth-tests-'));
const metadataFile = path.join(metadataDirectory, 'ward-metadata.json');
process.env.WARD_METADATA_FILE = metadataFile;

let state;
const normalize = sql => sql.replace(/\s+/g, ' ').trim();
const pool = {
  async execute(sql, params = []) {
    sql = normalize(sql);
    state.calls.push({ sql, params });
    if (sql.includes('FROM App_User u LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Id=? LIMIT 1')) {
      const user = state.users.get(Number(params[0]));
      return [user ? [{ ...user, LinkedOfficerId: state.officers.has(user.MaCanBo) ? user.MaCanBo : null }] : []];
    }
    if (sql === 'SELECT MaCanBo FROM Can_Bo WHERE MaCanBo=? LIMIT 1') return [state.officers.has(params[0]) ? [{MaCanBo:params[0]}] : []];
    if (sql === 'SELECT Id FROM App_User WHERE MaCanBo=? AND Id<>? LIMIT 1') return [[...state.users.values()].filter(user=>user.MaCanBo===params[0]&&String(user.Id)!==String(params[1])).map(user=>({Id:user.Id}))];
    if (sql.startsWith('SELECT cb.MaCanBo AS id, cb.HoTen AS name, cb.MaUBND AS officeId')) return [[...state.officers].filter(id=>!params.length||id===params[0]).map(id=>({id,name:id,officeId:'UB01',officeName:'Office'}))];
    if (sql === 'INSERT INTO App_User (Username,PasswordHash,DisplayName,Role,MaCanBo) VALUES (?,?,?,?,?)') {
      const [Username, PasswordHash, DisplayName, Role, MaCanBo] = params;
      const Id = state.nextId++;
      state.users.set(Id, { Id, Username, PasswordHash, DisplayName, Role, MaCanBo });
      state.inserted.push({ Id, Username, PasswordHash, DisplayName, Role, MaCanBo });
      return [{ insertId: Id, affectedRows: 1 }];
    }
    if (sql === 'SELECT Role, PasswordHash FROM App_User WHERE Username=? LIMIT 1') {
      const user = [...state.users.values()].find(user => user.Username === params[0]);
      return [user ? [{ Role: user.Role, PasswordHash: user.PasswordHash }] : []];
    }
    if (sql.includes('FROM App_User u LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Username=?')) {
      const user = [...state.users.values()].find(user => user.Username === params[0]);
      return [user ? [{ ...user, LinkedOfficerId:state.officers.has(user.MaCanBo)?user.MaCanBo:null }] : []];
    }
    if (sql === 'SELECT MaXaPhuong FROM Noi_Mat WHERE MaXaPhuong=?') {
      return [state.wards.has(params[0]) ? [{ MaXaPhuong: params[0] }] : []];
    }
    if (sql === 'INSERT INTO Noi_Mat (MaXaPhuong,TenXaPhuong) VALUES (?,?)') {
      state.wards.set(params[0], { id: params[0], name: params[1] });
      return [{ affectedRows: 1 }];
    }
    throw new Error(`Unexpected mock query: ${sql}`);
  },
  async query(sql, params = []) {
    sql = normalize(sql);
    state.calls.push({ sql, params });
    if (sql === "SELECT COUNT(*) AS admins FROM App_User WHERE Role='admin'") return [[{admins:[...state.users.values()].filter(user=>user.Role==='admin').length}]];
    if (sql === "SELECT COUNT(*) AS total FROM App_User WHERE Role='admin'") return [[{total:[...state.users.values()].filter(user=>user.Role==='admin').length}]];
    if (sql.includes('FROM App_User u LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo ORDER BY u.Role, u.Username')) {
      return [[...state.users.values()].map(user => ({
        id: user.Id, username: user.Username, name: user.DisplayName,
        role: user.Role, createdAt: '2026-01-01 00:00:00',officerId:user.MaCanBo||null,officerName:user.MaCanBo||null
      }))];
    }
    if (sql === 'SELECT MaXaPhuong AS id, TenXaPhuong AS name FROM Noi_Mat ORDER BY TenXaPhuong') {
      return [[...state.wards.values()].map(ward => ({ ...ward }))];
    }
    if (sql === 'SELECT MaCSYT AS id, TenCSYT AS name FROM CSYT ORDER BY TenCSYT'
      || sql === 'SELECT MaNguyenNhan AS id, TenNguyenNhan AS name FROM Nguyen_Nhan ORDER BY TenNguyenNhan'
      || sql === 'SELECT cb.MaCanBo AS id, cb.HoTen AS name, cb.MaUBND AS officeId, u.TenUBND AS officeName FROM Can_Bo cb JOIN UBND u ON u.MaUBND=cb.MaUBND ORDER BY cb.HoTen'
      || sql === 'SELECT MaUBND AS id, TenUBND AS name FROM UBND ORDER BY TenUBND') return [[]];
    throw new Error(`Unexpected mock query: ${sql}`);
  },
  async getConnection() {
    state.transactions.push('connect');
    return {
      async beginTransaction() { state.transactions.push('begin'); },
      async query(sql) {
        sql = normalize(sql);
        state.calls.push({ sql, params: [] });
        if (sql === "SELECT COUNT(*) AS total FROM App_User WHERE Role='admin' FOR UPDATE") {
          return [[{ total: [...state.users.values()].filter(user => user.Role === 'admin').length }]];
        }
        assert.equal(sql, "SELECT Id FROM App_User WHERE Role='admin' ORDER BY Id FOR UPDATE");
        const ids = state.lockedAdminIds ?? [...state.users.values()].filter(user => user.Role === 'admin').map(user => user.Id);
        return [ids.map(Id => ({ Id }))];
      },
      async execute(sql, params) {
        sql = normalize(sql);
        state.calls.push({ sql, params });
        if (sql.startsWith('SET SESSION sql_mode = IF(') && sql.includes('STRICT_TRANS_TABLES')) return [{ affectedRows: 0 }];
        if (sql === 'INSERT INTO Noi_Mat (MaXaPhuong,TenXaPhuong) VALUES (?,?)') {
          state.wards.set(params[0], { id: params[0], name: params[1] });
          return [{ affectedRows: 1 }];
        }
        if (sql === 'SELECT Id,Role,MaCanBo FROM App_User WHERE Id=? FOR UPDATE') {
          const user = state.users.get(Number(params[0]));
          return [user ? [{ Id: user.Id, Role: user.Role,MaCanBo:user.MaCanBo }] : []];
        }
        if (sql === 'UPDATE App_User SET Role=?,MaCanBo=? WHERE Id=?') {
          Object.assign(state.users.get(Number(params[2])),{Role:params[0],MaCanBo:params[1]});
          return [{ affectedRows: 1 }];
        }
        if (sql === 'SELECT MaCanBo FROM Can_Bo WHERE MaCanBo=? LIMIT 1' || sql === 'SELECT Id FROM App_User WHERE MaCanBo=? AND Id<>? LIMIT 1') return pool.execute(sql,params);
        throw new Error(`Unexpected transaction query: ${sql}`);
      },
      async commit() { state.transactions.push('commit'); },
      async rollback() { state.transactions.push('rollback'); },
      release() { state.transactions.push('release'); }
    };
  }
};

const databaseFile = require.resolve('../backend/config/database');
require.cache[databaseFile] = { id: databaseFile, filename: databaseFile, loaded: true, exports: { pool } };
const app = require('../backend/app');
const { recoveryAttempts, recoveryParts, verifyCredential, verifyRecovery, invitations, signupAttempts } = require('../backend/utils/auth');
const { loadWardMetadata, updateWardMetadata } = require('../backend/utils/ward-metadata');

after(() => {
  // Remove only the known temporary metadata file and its empty directory.
  assert.equal(path.dirname(metadataFile), metadataDirectory);
  fs.rmSync(metadataFile, { force: true });
  fs.rmdirSync(metadataDirectory);
});

beforeEach(() => {
  state = {
    users: new Map([
      [1, { Id: 1, Username: 'test_admin', DisplayName: 'Quản trị kiểm thử', Role: 'admin', PasswordHash: 'private-admin-credential' }],
      [2, { Id: 2, Username: 'test_staff', DisplayName: 'Cán bộ kiểm thử', Role: 'staff',MaCanBo:'CB01', PasswordHash: 'private-staff-credential' }],
      [3, { Id: 3, Username: 'second_admin', DisplayName: 'Quản trị thứ hai', Role: 'admin', PasswordHash: 'private-second-credential' }]
    ]),
    officers:new Set(['CB01','CB02','CB03','CB04']),
    wards: new Map([
      ['XA-TEST', { id: 'XA-TEST', name: 'Xã kiểm thử' }],
      ['PHUONG-TEST', { id: 'PHUONG-TEST', name: 'Phường kiểm thử' }]
    ]),
    calls: [], transactions: [], inserted: [], nextId: 4
  };
  recoveryAttempts.clear();
  invitations.clear(); signupAttempts.clear();
  fs.rmSync(metadataFile, { force: true });
});

const token = (id, role = 'admin') => jwt.sign({ id, role }, process.env.JWT_SECRET, { expiresIn: '5m' });
async function request(method, path, { session, body } = {}) {
  // Real Node HTTP request/response objects run through every Express middleware.
  // The duplex sink avoids TCP, which is unavailable in the restricted test environment.
  return new Promise((resolve, reject) => {
    const socket = new Duplex({ read() {}, write(_chunk, _encoding, callback) { callback(); } });
    const req = new IncomingMessage(socket);
    req.method = method;
    req.url = path;
    req.headers = { host: 'localhost' };
    req.httpVersion = '1.1';
    if (session !== undefined) req.headers.cookie = `session=${session}`;
    const payload = body === undefined ? undefined : Buffer.from(JSON.stringify(body));
    if (payload) {
      req.headers['content-type'] = 'application/json';
      req.headers['content-length'] = String(payload.length);
    }
    const res = new ServerResponse(req);
    res.assignSocket(socket);
    const chunks = [];
    const write = res.write;
    const end = res.end;
    res.write = function (chunk, encoding, callback) {
      if (chunk) chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk, typeof encoding === 'string' ? encoding : undefined));
      return write.call(this, chunk, encoding, callback);
    };
    res.end = function (chunk, encoding, callback) {
      if (chunk) chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk, typeof encoding === 'string' ? encoding : undefined));
      return end.call(this, chunk, encoding, callback);
    };
    const timer = setTimeout(() => { socket.destroy(); reject(new Error(`In-memory HTTP timeout: ${method} ${path}`)); }, 10000);
    res.on('error', reject);
    res.on('finish', () => {
      clearTimeout(timer);
      socket.destroy();
      try {
        resolve({
          status: res.statusCode,
          body: JSON.parse(Buffer.concat(chunks).toString('utf8')),
          headers: { get(name) {
            const value = res.getHeader(name);
            return value === undefined ? null : Array.isArray(value) ? value.join(', ') : String(value);
          } }
        });
      } catch (error) { reject(error); }
    });
    if (payload) req.push(payload);
    req.complete = true;
    req.push(null);
    app.handle(req, res);
  });
}

test('protected APIs reject requests without a session before querying the database', async () => {
  const response = await request('GET', '/api/users');
  assert.equal(response.status, 401);
  assert.match(response.body.error, /đăng nhập/);
  assert.equal(state.calls.length, 0);
});

test('a forged session is rejected and cleared', async () => {
  const response = await request('GET', '/api/users', { session: 'invalid.jwt.session' });
  assert.equal(response.status, 401);
  assert.match(response.headers.get('set-cookie'), /session=;/);
  assert.equal(state.calls.length, 0);
});

for (const [method, path, body] of [
  ['GET', '/api/users'],
  ['POST', '/api/users', {}],
  ['PATCH', '/api/users/3/role', { role: 'staff' }],
  ['POST', '/api/master/cause', { id: 'TEST', name: 'Nguyên nhân kiểm thử' }],
  ['PATCH', '/api/master/ward/TEST', { province: 'Hà Nội', unitType: 'Xã' }],
  ['DELETE', '/api/registrations/TEST']
]) {
  test(`staff cannot perform ${method} ${path}`, async () => {
    const response = await request(method, path, { session: token(2, 'staff'), body });
    assert.equal(response.status, 403);
    assert.equal(state.calls.length, 1, 'permission failure must precede feature queries');
    assert.deepEqual(state.transactions, []);
  });
}

test('admin account listing returns public fields without password credentials', async () => {
  const response = await request('GET', '/api/users', { session: token(1) });
  assert.equal(response.status, 200);
  assert.equal(response.body.length, 3);
  assert.deepEqual(Object.keys(response.body[0]).sort(), ['createdAt', 'id', 'name', 'officerId', 'officerName', 'role', 'username']);
  assert.doesNotMatch(state.calls[1].sql, /PasswordHash|SELECT\s+\*/i);
  assert.doesNotMatch(JSON.stringify(response.body), /private-|PasswordHash/);
});

test('a role change in the database takes effect on the next request with the same JWT', async () => {
  const session = token(1, 'admin');
  assert.equal((await request('GET', '/api/users', { session })).status, 200);
  state.users.get(1).Role = 'staff';
  assert.equal((await request('GET', '/api/users', { session })).status, 403);
  assert.equal(state.calls.filter(call => call.sql.includes('WHERE u.Id=? LIMIT 1')).length, 2);
});

test('deleted accounts cannot retain access through an unexpired JWT', async () => {
  state.users.delete(1);
  assert.equal((await request('GET', '/api/users', { session: token(1) })).status, 401);
});

const newUser = role => ({
  username: `new_${role}`, displayName: 'Tài khoản kiểm thử', password: 'test-password-2026',
  securityQuestion: 'first_teacher', securityAnswer: 'Câu trả lời kiểm thử', role,officerId:role==='staff'?'CB02':null
});

test('creating an account rejects an unsupported role before hashing or insertion', async () => {
  const response = await request('POST', '/api/users', { session: token(1), body: newUser('superadmin') });
  assert.equal(response.status, 400);
  assert.match(response.body.error, /ADMIN|Cán bộ/);
  assert.equal(state.inserted.length, 0);
});

for (const role of ['admin', 'staff']) {
  test(`admin can create a ${role} account with real hashed credentials`, async () => {
    const body = newUser(role);
    const response = await request('POST', '/api/users', { session: token(1), body });
    assert.equal(response.status, 201);
    assert.equal(state.inserted.length, 1);
    const created = state.inserted[0];
    assert.equal(created.Role, role);
    assert.equal(created.Username, body.username);
    assert.equal(created.DisplayName, body.displayName);
    assert.equal(recoveryParts(created.PasswordHash).questionId, body.securityQuestion);
    assert.equal(await verifyCredential(body.password, created.PasswordHash), true);
    assert.equal(await verifyRecovery(body.securityQuestion, body.securityAnswer, created.PasswordHash), true);
    assert.doesNotMatch(JSON.stringify(response.body), /recovery-v1|test-password/);
  });
}

test('an admin cannot demote their own active account', async () => {
  const response = await request('PATCH', '/api/users/1/role', { session: token(1), body: { role: 'staff' } });
  assert.equal(response.status, 409);
  assert.equal(state.users.get(1).Role, 'admin');
  assert.deepEqual(state.transactions, []);
});

test('the last admin is protected if another admin was demoted concurrently', async () => {
  // Simulate the current actor losing its role after authentication but before the transaction lock.
  state.lockedAdminIds = [3];
  const response = await request('PATCH', '/api/users/3/role', { session: token(1), body: { role: 'staff' } });
  assert.equal(response.status, 409);
  assert.equal(state.users.get(3).Role, 'admin');
  assert.deepEqual(state.transactions, ['connect', 'begin', 'rollback', 'release']);
  assert.equal(state.calls.some(call => call.sql.startsWith('UPDATE ')), false);
});

test('an admin can demote another admin inside a committed transaction', async () => {
  const response = await request('PATCH', '/api/users/3/role', { session: token(1), body: { role: 'staff',officerId:'CB02' } });
  assert.equal(response.status, 200);
  assert.equal(state.users.get(3).Role, 'staff');
  assert.deepEqual(state.transactions, ['connect', 'begin', 'commit', 'release']);
  assert.deepEqual(state.calls.find(call => call.sql.startsWith('UPDATE ')).params, ['staff','CB02', '3']);
});

test('public password reset rejects the removed hardcoded admin-name answer', async () => {
  state.users.get(1).PasswordHash = await bcrypt.hash('original-test-password', 4);
  const response = await request('POST', '/api/auth/reset-password', {
    body: { username: 'test_admin', password: 'replacement-test-password', securityQuestion: '__admin_name__', securityAnswer: 'Hùng' }
  });
  assert.equal(response.status, 400);
  assert.equal(state.calls.some(call => call.sql.startsWith('UPDATE ')), false);
  assert.equal(await bcrypt.compare('original-test-password', state.users.get(1).PasswordHash), true);
});

test('public recovery question does not offer an admin-name fallback for legacy accounts', async () => {
  state.users.get(1).PasswordHash = await bcrypt.hash('original-test-password', 4);
  const response = await request('POST', '/api/auth/recovery-question', { body: { username: 'test_admin' } });
  assert.equal(response.status, 404);
  assert.equal(response.body.allowAdminNameFallback, undefined);
});

test('initial setup cannot replace an existing admin account', async () => {
  const response = await request('POST', '/api/auth/setup', { body: newUser('admin') });
  assert.equal(response.status, 409);
  assert.deepEqual(state.transactions, ['connect', 'begin', 'rollback', 'release']);
  assert.equal(state.inserted.length, 0);
});

test('login verifies a real password and issues a safe user response and signed session', async () => {
  state.users.get(1).PasswordHash = await bcrypt.hash('original-test-password', 4);
  const response = await request('POST', '/api/auth/login', {
    body: { username: 'test_admin', password: 'original-test-password' }
  });
  assert.equal(response.status, 200);
  assert.deepEqual(response.body.user, {
    id: 1, username: 'test_admin', name: 'Quản trị kiểm thử', role: 'admin',officerId:null, recoveryConfigured: false
  });
  const cookie = response.headers.get('set-cookie');
  assert.match(cookie, /HttpOnly/);
  assert.match(cookie, /SameSite=Strict/);
  const session = cookie.match(/session=([^;]+)/)[1];
  const claims = jwt.verify(session, process.env.JWT_SECRET);
  assert.equal(claims.id, 1);
  assert.equal(claims.role, 'admin');
  assert.doesNotMatch(JSON.stringify(response.body), /PasswordHash|original-test-password|\$2[aby]\$/);
});

test('login with an incorrect password does not issue a session', async () => {
  state.users.get(1).PasswordHash = await bcrypt.hash('original-test-password', 4);
  const response = await request('POST', '/api/auth/login', {
    body: { username: 'test_admin', password: 'wrong-test-password' }
  });
  assert.equal(response.status, 401);
  assert.equal(response.headers.get('set-cookie'), null);
});

test('lookup merges separate JSON classification without changing the original ward rows', async () => {
  await updateWardMetadata('XA-TEST', { province: 'Hà Nội', unitType: 'Xã' });
  const response = await request('GET', '/api/lookups', { session: token(2, 'staff') });
  assert.equal(response.status, 200);
  assert.deepEqual(response.body.wards, [
    { id: 'XA-TEST', name: 'Xã kiểm thử', province: 'Hà Nội', unitType: 'Xã' },
    { id: 'PHUONG-TEST', name: 'Phường kiểm thử', province: null, unitType: null }
  ]);
  assert.deepEqual(state.wards.get('XA-TEST'), { id: 'XA-TEST', name: 'Xã kiểm thử' });
  assert.equal(state.calls.every(call => call.sql.startsWith('SELECT ')), true);
});

test('classifying an existing ward changes only the separate JSON file', async () => {
  const response = await request('PATCH', '/api/master/ward/XA-TEST', {
    session: token(1), body: { province: '  Hà Nội  ', unitType: 'Xã' }
  });
  assert.equal(response.status, 200);
  assert.deepEqual(JSON.parse(fs.readFileSync(metadataFile, 'utf8')), {
    'XA-TEST': { province: 'Hà Nội', unitType: 'Xã' }
  });
  assert.equal(state.calls.every(call => call.sql.startsWith('SELECT ')), true);
  assert.deepEqual(state.wards.get('XA-TEST'), { id: 'XA-TEST', name: 'Xã kiểm thử' });
});

test('classifying an unknown ward returns 404 without creating a metadata file', async () => {
  const response = await request('PATCH', '/api/master/ward/MISSING', {
    session: token(1), body: { province: 'Hà Nội', unitType: 'Xã' }
  });
  assert.equal(response.status, 404);
  assert.equal(fs.existsSync(metadataFile), false);
  assert.equal(state.calls.every(call => call.sql.startsWith('SELECT ')), true);
});

test('invalid ward classification returns 400 before any feature query or file write', async () => {
  for (const body of [{ province: '', unitType: 'Xã' }, { province: 'Hà Nội', unitType: 'Tỉnh' }]) {
    const response = await request('PATCH', '/api/master/ward/XA-TEST', { session: token(1), body });
    assert.equal(response.status, 400);
  }
  assert.equal(state.calls.length, 2, 'only session-role lookups should run');
  assert.equal(fs.existsSync(metadataFile), false);
});

test('creating a ward uses the original two-column schema and stores classification separately', async () => {
  const response = await request('POST', '/api/master/ward', {
    session: token(1), body: { id: ' NEW-TEST ', name: ' Xã mới kiểm thử ', province: 'Hà Nội', unitType: 'Xã' }
  });
  assert.equal(response.status, 201);
  const insertion = state.calls.find(call => call.sql.startsWith('INSERT '));
  assert.equal(insertion.sql, 'INSERT INTO Noi_Mat (MaXaPhuong,TenXaPhuong) VALUES (?,?)');
  assert.deepEqual(insertion.params, ['NEW-TEST', 'Xã mới kiểm thử']);
  assert.ok(state.calls.findIndex(call => call.sql.startsWith('SET SESSION sql_mode')) < state.calls.indexOf(insertion));
  assert.deepEqual(JSON.parse(fs.readFileSync(metadataFile, 'utf8')), {
    'NEW-TEST': { province: 'Hà Nội', unitType: 'Xã' }
  });
  assert.equal(state.calls.some(call => /^(ALTER|CREATE|DROP|UPDATE) /i.test(call.sql)), false);
});

test('metadata updates are serialized without lost wards and leave no temporary files', async () => {
  const empty = await loadWardMetadata();
  assert.equal(Object.getPrototypeOf(empty), null);
  await Promise.all(Array.from({ length: 10 }, (_, index) => updateWardMetadata(`TEST-${index}`, {
    province: 'Hà Nội', unitType: index % 2 ? 'Phường' : 'Xã'
  })));
  const metadata = await loadWardMetadata();
  assert.equal(Object.keys(metadata).length, 10);
  for (let index = 0; index < 10; index++) {
    assert.deepEqual(metadata[`TEST-${index}`], { province: 'Hà Nội', unitType: index % 2 ? 'Phường' : 'Xã' });
  }
  assert.deepEqual(fs.readdirSync(metadataDirectory), ['ward-metadata.json']);
  assert.equal(state.calls.length, 0);
});

test('metadata loader rejects an invalid top-level structure', async () => {
  fs.writeFileSync(metadataFile, '[]', 'utf8');
  await assert.rejects(loadWardMetadata, /cấu hình địa bàn không hợp lệ/);
  assert.equal(state.calls.length, 0);
});

test('staff scope ignores forged role and officer claims in a valid signed token', async () => {
  const session=jwt.sign({id:2,role:'admin',officerId:'CB04'},process.env.JWT_SECRET);
  const response=await request('GET','/api/lookups',{session});
  assert.equal(response.status,200);assert.deepEqual(response.body.officers.map(row=>row.id),['CB01']);
});
test('changing the current DB officer binding affects the same token', async () => {
  const session=token(2,'staff');state.users.get(2).MaCanBo='CB03';
  const response=await request('GET','/api/lookups',{session});
  assert.equal(response.status,200);assert.deepEqual(response.body.officers.map(row=>row.id),['CB03']);
});
for(const binding of [null,'MISSING']) {
  test(`staff API fails closed for invalid binding ${binding}`,async()=>{
    state.users.get(2).MaCanBo=binding;
    const response=await request('GET','/api/lookups',{session:token(2,'staff')});
    assert.equal(response.status,403);assert.equal(state.calls.length,1);
  });
  test(`staff login refuses invalid binding ${binding}`,async()=>{
    Object.assign(state.users.get(2),{MaCanBo:binding,PasswordHash:await bcrypt.hash('staff-password-2026',4)});
    const response=await request('POST','/api/auth/login',{body:{username:'test_staff',password:'staff-password-2026'}});
    assert.equal(response.status,403);assert.equal(response.headers.get('set-cookie'),null);
  });
}
test('valid staff login returns the linked officer without credentials',async()=>{
  state.users.get(2).PasswordHash=await bcrypt.hash('staff-password-2026',4);
  const response=await request('POST','/api/auth/login',{body:{username:'test_staff',password:'staff-password-2026'}});
  assert.equal(response.status,200);assert.equal(response.body.user.officerId,'CB01');assert.doesNotMatch(JSON.stringify(response.body),/PasswordHash|staff-password/);
});
for(const [binding,status] of [[undefined,400],['MISSING',400],['CB01',409]]) {
  test(`staff creation rejects invalid or occupied officer ${binding}`,async()=>{
    const response=await request('POST','/api/users',{session:token(1),body:{...newUser('staff'),officerId:binding}});
    assert.equal(response.status,status);assert.equal(state.inserted.length,0);
  });
}
test('ADMIN account creation does not retain a supplied officer binding',async()=>{
  const response=await request('POST','/api/users',{session:token(1),body:{...newUser('admin'),officerId:'CB01'}});
  assert.equal(response.status,201);assert.equal(state.inserted[0].MaCanBo,null);
});
test('demotion to staff requires an explicit valid receiving officer',async()=>{
  const response=await request('PATCH','/api/users/3/role',{session:token(1),body:{role:'staff'}});
  assert.equal(response.status,400);assert.equal(state.users.get(3).Role,'admin');assert.ok(state.transactions.includes('rollback'));
});
test('ADMIN can reassign a staff officer while keeping the same role',async()=>{
  const response=await request('PATCH','/api/users/2/role',{session:token(1),body:{role:'staff',officerId:'CB03'}});
  assert.equal(response.status,200);assert.equal(state.users.get(2).MaCanBo,'CB03');
});
test('reassignment cannot take an officer already linked to another account',async()=>{
  state.users.get(3).MaCanBo='CB03';
  const response=await request('PATCH','/api/users/2/role',{session:token(1),body:{role:'staff',officerId:'CB03'}});
  assert.equal(response.status,409);assert.equal(state.users.get(2).MaCanBo,'CB01');
});
test('promoting staff to ADMIN clears the receiving-officer binding',async()=>{
  const response=await request('PATCH','/api/users/2/role',{session:token(1),body:{role:'admin',officerId:'CB01'}});
  assert.equal(response.status,200);assert.equal(state.users.get(2).Role,'admin');assert.equal(state.users.get(2).MaCanBo,null);
});
for(const [binding,status] of [['MISSING',400],['CB01',409]]) {
  test(`invitation rejects unavailable officer ${binding}`,async()=>{
    const response=await request('POST','/api/invitations',{session:token(1),body:{officerId:binding}});
    assert.equal(response.status,status);assert.equal(invitations.size,0);
  });
}
test('invited registration cannot change the server-selected officer or request ADMIN',async()=>{
  const invite=await request('POST','/api/invitations',{session:token(1),body:{officerId:'CB02'}});
  assert.equal(invite.status,201);
  const response=await request('POST','/api/auth/register',{body:{...newUser('admin'),inviteCode:invite.body.code,officerId:'CB04'}});
  assert.equal(response.status,201);assert.equal(state.inserted[0].Role,'staff');assert.equal(state.inserted[0].MaCanBo,'CB02');
});
test('a one-use invitation cannot be claimed concurrently by two registrations',async()=>{
  invitations.set('ONCE',{officerId:'CB02',expiresAt:Date.now()+60000,used:false});
  const responses=await Promise.all(['first_signup','second_signup'].map(username=>request('POST','/api/auth/register',{body:{...newUser('staff'),username,inviteCode:'ONCE'}})));
  assert.deepEqual(responses.map(row=>row.status).sort(),[201,403]);assert.equal(state.inserted.length,1);
});
test('legacy invitations without an officer do not create unbound staff',async()=>{
  invitations.set('OLD',{expiresAt:Date.now()+60000,used:false});
  const response=await request('POST','/api/auth/register',{body:{...newUser('staff'),inviteCode:'OLD'}});
  assert.equal(response.status,400);assert.equal(state.inserted.length,0);
});
