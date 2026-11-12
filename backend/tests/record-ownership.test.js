const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const { scopedReport, genderQuery, yearQuery, areaQuery, ageCauseQuery, hospitalQuery } = require('../modules/reports/queries');

const admin = { role: 'admin' };
const staff = { role: 'staff', officerId: 'CB01' };
const records = [
  { id: 'HS01', officerId: 'CB01', deceasedId: '001234567890', status: 'Chờ xử lý' },
  { id: 'HS02', officerId: 'CB02', deceasedId: '001234567891', status: 'Đã duyệt' }
];

function routesFor(relativeFile, pool) {
  const filename = path.join(__dirname, '..', relativeFile);
  const localRequire = createRequire(filename);
  const routes = [];
  const router = Object.fromEntries(['get', 'post', 'patch', 'delete', 'use'].map(method => [method,
    (routePath, ...handlers) => routes.push({ method, path: routePath, handlers })]));
  const module = { exports: {} };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), {
    module, exports: module.exports,
    require(name) {
      if (name === 'express') return { Router: () => router };
      if (name.endsWith('/config/database')) return { pool };
      if (name.endsWith('/middleware/auth')) return { adminOnly: (_req, _res, next) => next() };
      return localRequire(name);
    }
  }, { filename });
  return routes;
}

async function invoke(route, request = {}) {
  const response = { statusCode: 200, body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = JSON.parse(JSON.stringify(body)); return this; } };
  let error;
  await route.handlers.at(-1)({ user: staff, query: {}, params: {}, ...request }, response, value => { error = value; });
  return { response, error };
}

function registrationPool() {
  const calls = [];
  const pool = {
    calls,
    async execute(sql, params = []) {
      calls.push({ sql, params: Array.from(params) });
      let rows = records;
      if (/h\.MaCanBoTiepNhan=\?/.test(sql)) rows = rows.filter(row => row.officerId === params.at(-1));
      if (/WHERE d\.CCCD=\?/.test(sql)) rows = rows.filter(row => row.deceasedId === params[0]);
      if (/WHERE h\.SoGiayKhaiTu=\?/.test(sql)) rows = rows.filter(row => row.id === params[0]);
      return [rows.map(row => ({ ...row, CCCD_NgMat: row.deceasedId }))];
    },
    async getConnection() {
      return {
        async execute(sql, params = []) {
          if (sql.startsWith('SELECT ')) return pool.execute(sql, params);
          calls.push({ sql, params: Array.from(params) });
          return [{ affectedRows: 1 }];
        },
        async beginTransaction() {}, async commit() {}, async rollback() {}, release() {}
      };
    }
  };
  return pool;
}

function payload(officerId) {
  return {
    deceased: { cccd: '001234567892', name: 'Người mất thử', birthDate: '1940-01-01', gender: 'Nam' },
    applicant: { cccd: '001234567893', name: 'Người đăng ký thử', birthDate: '1980-01-01', gender: 'Nữ' },
    certificate: { id: 'GBT-TEST', issuedAt: '2026-11-09', deathAt: '2026-11-08T12:00', causeId: 'NN01', wardId: 'XA01', hospitalId: 'CS01' },
    registration: { id: 'HS-TEST', registeredAt: '2026-11-09', relation: 'Người thân', officerId }
  };
}

test('cán bộ chỉ nhận danh sách và tra cứu CCCD của mình, tham số giả không đổi quyền', async () => {
  const pool = registrationPool();
  const routes = routesFor('modules/registrations/index.js', pool);
  const list = routes.find(route => route.method === 'get' && route.path === '/');
  const lookup = routes.find(route => route.method === 'get' && route.path === '/:cccd');
  const own = await invoke(list, { query: { officerId: 'CB02', search: '' }, body: { officerId: 'CB02' } });
  assert.equal(own.error, undefined);
  assert.deepEqual(own.response.body.map(row => row.id), ['HS01']);
  assert.equal(pool.calls[0].params.at(-1), 'CB01');
  const found = await invoke(lookup, { params: { cccd: records[0].deceasedId } });
  assert.equal(found.response.body.id, 'HS01');
  const foreign = await invoke(lookup, { params: { cccd: records[1].deceasedId }, query: { officerId: 'CB02' } });
  assert.equal(foreign.response.statusCode, 404);
  const all = await invoke(list, { user: admin });
  assert.deepEqual(all.response.body.map(row => row.id), ['HS01', 'HS02']);
  assert.doesNotMatch(pool.calls.at(-1).sql, /h\.MaCanBoTiepNhan=\?/);
});

test('cán bộ cập nhật được hồ sơ của mình, hồ sơ cán bộ khác trả 404 và không ghi dữ liệu', async () => {
  const pool = registrationPool();
  const patch = routesFor('modules/registrations/index.js', pool).find(route => route.method === 'patch');
  const foreign = await invoke(patch, { params: { id: 'HS02' }, body: { status: 'Từ chối', officerId: 'CB02' } });
  assert.equal(foreign.error, undefined);
  assert.equal(foreign.response.statusCode, 404);
  assert.ok(!pool.calls.some(call => call.sql.startsWith('UPDATE ')));
  const own = await invoke(patch, { params: { id: 'HS01' }, body: { status: 'Đã duyệt' } });
  assert.equal(own.error, undefined);
  assert.equal(own.response.body.status, 'Đã duyệt');
  const update = pool.calls.find(call => call.sql.startsWith('UPDATE Ho_So'));
  assert.match(update.sql, /h\.MaCanBoTiepNhan=\?/);
  assert.deepEqual(update.params, ['Đã duyệt', 'HS01', 'CB01']);
  const global = await invoke(patch, { user: admin, params: { id: 'HS02' }, body: { status: 'Từ chối' } });
  assert.equal(global.response.statusCode, 200);
});

test('không cho cán bộ tạo hồ sơ gắn người tiếp nhận khác; ADMIN vẫn chọn được người tiếp nhận', async () => {
  const pool = registrationPool();
  const create = routesFor('modules/registrations/index.js', pool).find(route => route.method === 'post');
  const forged = await invoke(create, { body: payload('CB02') });
  assert.equal(forged.error.statusCode, 403);
  assert.equal(pool.calls.length, 0);
  const own = await invoke(create, { body: payload('CB01') });
  assert.equal(own.response.statusCode, 201);
  assert.equal(pool.calls.find(call => call.sql.startsWith('INSERT INTO Ho_So')).params.at(-1), 'CB01');
  const global = await invoke(create, { user: admin, body: payload('CB02') });
  assert.equal(global.response.statusCode, 201);
  assert.equal(pool.calls.filter(call => call.sql.startsWith('INSERT INTO Ho_So')).at(-1).params.at(-1), 'CB02');
});

test('mọi báo cáo giữ quy tắc gốc và thêm đúng phạm vi cán bộ bằng tham số', async () => {
  const cases = [
    ['gender', 'gender', genderQuery, /c\.TrangThai='Đã mất'/, []],
    ['years', 'years', yearQuery, /YEAR\(g\.NgayGioMat\)/, []],
    ['areas', 'areas', areaQuery, /h\.TrangThaiHoSo <> 'Từ chối'/, ['2026-01-01', '2027-01-01']],
    ['age-causes', 'ageCauses', ageCauseQuery, /h\.TrangThaiHoSo='Đã duyệt'/, []],
    ['hospitals', 'hospitals', hospitalQuery, /HAVING COUNT\(\*\) > 50/, ['2026-07-01', '2026-10-01']]
  ];
  for (const [folder, key, original, semantic, dateParams] of cases) {
    assert.equal(scopedReport(key, null, dateParams).sql, original);
    const calls = [];
    const route = routesFor(`modules/reports/${folder}/index.js`, {
      async execute(sql, params) { calls.push({ sql, params: Array.from(params) }); return [[]]; }
    })[0];
    const result = await invoke(route, { query: { year: '2026', officerId: 'CB02' } });
    assert.equal(result.error, undefined, folder);
    assert.equal(calls.length, 1, folder);
    assert.equal(calls[0].params.at(-1), 'CB01', folder);
    assert.match(calls[0].sql, /MaCanBoTiepNhan=\?/, folder);
    assert.match(calls[0].sql, semantic, folder);
    if (folder === 'areas') {
      assert.match(calls[0].sql, /LEFT JOIN Ho_So_Khai_Tu h[\s\S]+AND h\.MaCanBoTiepNhan=\?\n  GROUP BY/);
      assert.doesNotMatch(calls[0].sql, /WHERE h\.MaCanBoTiepNhan/);
      assert.deepEqual(calls[0].params.slice(0, 2), dateParams);
    }
    const adminResult = await invoke(route, { user: admin, query: { year: '2026' } });
    assert.equal(adminResult.error, undefined);
    assert.equal(calls.at(-1).sql, original, folder);
  }
});

test('tổng quan lọc cả bốn nguồn và danh mục cán bộ tiếp nhận chỉ trả chính mình', async () => {
  const calls = [];
  const dashboard = routesFor('modules/dashboard/index.js', {
    async execute(sql, params) {
      calls.push({ sql, params: Array.from(params) });
      if (calls.length === 1) return [[{ total: 1, thisMonth: 1, completed: 0, active: 1 }]];
      return calls.length === 4 ? [[records[0]]] : [[]];
    }
  })[0];
  const result = await invoke(dashboard);
  assert.equal(result.error, undefined);
  assert.equal(result.response.body.cards.total, 1);
  assert.deepEqual(result.response.body.recent.map(row => row.id), ['HS01']);
  assert.equal(calls.length, 4);
  for (const call of calls) {
    assert.match(call.sql, /MaCanBoTiepNhan=\?/);
    assert.deepEqual(call.params, ['CB01']);
  }
  let officerCall;
  const lookups = routesFor('modules/catalogs/index.js', {
    async query() { return [[]]; },
    async execute(sql, params) {
      officerCall = { sql, params: Array.from(params) };
      return [[{ id: 'CB01', name: 'Cán bộ thử' }]];
    }
  }).find(route => route.path === '/lookups');
  const dictionaries = await invoke(lookups, { query: { officerId: 'CB02' } });
  assert.equal(dictionaries.error, undefined);
  assert.deepEqual(dictionaries.response.body.officers.map(row => row.id), ['CB01']);
  assert.match(officerCall.sql, /WHERE cb\.MaCanBo=\?/);
  assert.deepEqual(officerCall.params, ['CB01']);
});

test('tài khoản thiếu liên kết hoặc thiếu danh tính bị chặn trước mọi truy cập dữ liệu', async () => {
  let calls = 0;
  const unavailablePool = Object.fromEntries(['query', 'execute', 'getConnection'].map(method => [method, () => { calls += 1; throw new Error('Không được đọc DB'); }]));
  const routes = [
    ...routesFor('modules/registrations/index.js', unavailablePool).filter(route => route.method !== 'delete'),
    ...routesFor('modules/dashboard/index.js', unavailablePool),
    ...['gender', 'years', 'areas', 'age-causes', 'hospitals'].flatMap(folder => routesFor(`modules/reports/${folder}/index.js`, unavailablePool)),
    ...routesFor('modules/catalogs/index.js', unavailablePool).filter(route => route.path === '/lookups')
  ];
  for (const user of [{ role: 'staff' }, { role: 'staff', officerId: '' }, { role: 'other', officerId: 'CB01' }, undefined]) {
    for (const route of routes) {
      const result = await invoke(route, { user, body: payload('CB01') });
      assert.equal(result.error?.statusCode, 403, `${route.method} ${route.path}`);
    }
  }
  assert.equal(calls, 0);
});
