const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createRequire } = require('node:module');
const { previousQuarter, parseYear, summarizeAgeCauses } = require('../modules/reports/helpers');
const { validDate, validDateTime, validCccd } = require('../modules/registrations/validation');

function loadRoutes(relativeFile, pool, overrides = {}) {
  const filename = path.join(__dirname, '..', relativeFile);
  const localRequire = createRequire(filename);
  const routes = [];
  const router = Object.fromEntries(['get', 'post', 'patch', 'delete', 'use'].map(method => [method,
    (routePath, ...handlers) => routes.push({ method, path: routePath, handlers })]));
  const module = { exports: {} };
  vm.runInNewContext(fs.readFileSync(filename, 'utf8'), {
    module, exports: module.exports,
    require(name) {
      if (Object.hasOwn(overrides, name)) return overrides[name];
      if (name === 'express') return { Router: () => router };
      if (name.endsWith('/config/database')) return { pool };
      if (name.endsWith('/middleware/auth')) return { adminOnly: (_req, _res, next) => next() };
      return localRequire(name);
    }
  }, { filename });
  return routes;
}

async function invoke(route, request) {
  request = { user: { role: 'admin' }, ...request };
  const response = {
    statusCode: 200, body: undefined,
    status(code) { this.statusCode = code; return this; },
    json(body) { this.body = JSON.parse(JSON.stringify(body)); return this; }
  };
  let error;
  await route.handlers.at(-1)(request, response, nextError => { error = nextError; });
  return { response, error };
}

test('quý gần nhất là quý lịch hoàn chỉnh, gồm chuyển năm và múi giờ Việt Nam', () => {
  assert.deepEqual(previousQuarter(new Date('2026-11-09T00:00:00Z')), {
    start: '2026-07-01', end: '2026-10-01', label: 'Quý 3/2026', timeZone: 'Asia/Ho_Chi_Minh'
  });
  assert.equal(previousQuarter(new Date('2026-12-31T16:59:59Z')).label, 'Quý 3/2026');
  assert.deepEqual(previousQuarter(new Date('2026-12-31T17:00:00Z')), {
    start: '2026-10-01', end: '2027-01-01', label: 'Quý 4/2026', timeZone: 'Asia/Ho_Chi_Minh'
  });
  assert.equal(previousQuarter(new Date('2027-03-31T17:00:00Z')).label, 'Quý 1/2027');
});

test('nhóm tuổi luôn đủ ba nhóm, trả tất cả nguyên nhân đồng hạng và tách dữ liệu lỗi', () => {
  const report = summarizeAgeCauses([
    { ageGroup: 'Dưới 18', cause: 'Bệnh A', value: 2 },
    { ageGroup: 'Dưới 18', cause: 'Bệnh B', value: '2' },
    { ageGroup: 'Dưới 18', cause: 'Bệnh C', value: 1 },
    { ageGroup: 'Trên 60', cause: null, value: 3 },
    { ageGroup: '__invalid__', cause: 'Bệnh A', value: 4 },
    { ageGroup: '__unknown__', cause: 'Bệnh A', value: 5 }
  ]);
  assert.deepEqual(report.rows.map(row => [row.ageGroup, row.total]), [
    ['Dưới 18', 5], ['18–60', 0], ['Trên 60', 3]
  ]);
  assert.deepEqual(report.rows[0].commonCauses.map(row => row.cause), ['Bệnh A', 'Bệnh B']);
  assert.deepEqual(report.rows[1].commonCauses, []);
  assert.equal(report.rows[2].commonCauses[0].cause, 'Chưa rõ nguyên nhân');
  assert.equal(report.invalidCount, 4);
  assert.equal(report.unknownCount, 5);
});

test('năm theo múi giờ Việt Nam và từ chối giá trị không phải một năm cụ thể', () => {
  assert.equal(parseYear(undefined, new Date('2026-12-31T17:00:00Z')), 2027);
  assert.equal(parseYear('2024'), 2024);
  for (const value of ['0', '2026 OR 1=1', '2026.5', '-2026', '10000', ['2026'], '9999']) {
    assert.throws(() => parseYear(value), { statusCode: 400 });
  }
});

test('kiểm tra ngày thật, năm nhuận, giờ mất và CCCD giữ số 0 đầu', () => {
  assert.equal(validDate('2024-02-29'), true);
  assert.equal(validDate('2026-02-29'), false);
  assert.equal(validDate('2026-04-31'), false);
  assert.equal(validDateTime('2026-11-09T23:59'), true);
  assert.equal(validDateTime('2026-11-09 23:59:59'), true);
  assert.equal(validDateTime('2026-11-09T24:00'), false);
  assert.equal(validDateTime('2026-11-09T12:60'), false);
  assert.equal(validDateTime('2026-11-09'), false);
  assert.equal(validCccd('001234567890'), true);
  assert.equal(validCccd(123456789012), false);
  assert.equal(validCccd('1234'), false);
});

test('tra cứu CCCD sai bị chặn trước khi truy cập DB; CCCD hợp lệ được truyền nguyên vẹn', async () => {
  let calls = 0;
  let boundParameters;
  const rows = loadRoutes('modules/registrations/index.js', {
    async execute(_sql, params) { calls += 1; boundParameters = params; return [[{ id: 'TEST', causeDescription: 'Chi tiết' }]]; }
  });
  const lookup = rows.find(route => route.method === 'get' && route.path === '/:cccd');
  const invalid = await invoke(lookup, { params: { cccd: '123 OR 1=1' } });
  assert.equal(invalid.response.statusCode, 400);
  assert.equal(calls, 0);
  const valid = await invoke(lookup, { params: { cccd: '001234567890' } });
  assert.equal(valid.error, undefined);
  assert.equal(valid.response.body.causeDescription, 'Chi tiết');
  assert.deepEqual(Array.from(boundParameters), ['001234567890']);
  assert.equal(calls, 1);
});

test('địa bàn giữ tất cả xã/phường kể cả 0 ca, không lọc bằng metadata JSON', async () => {
  const calls = [];
  const routes = loadRoutes('modules/reports/areas/index.js', {
    async execute(sql, params) {
      assert.doesNotMatch(sql, /TinhThanh|LoaiDonVi/);
      calls.push(params);
      return [[
        { id: 'TEST', name: 'Xã thử nghiệm', value: 0 },
        { id: 'WARD', name: 'Phường thử nghiệm', value: 8 },
        { id: 'OTHER', name: 'Xã tỉnh khác', value: 6 },
        { id: 'UNKNOWN-1', name: 'Chưa phân loại 1', value: 3 },
        { id: 'UNKNOWN-2', name: 'Chưa phân loại 2', value: 2 }
      ]];
    }
  }, {
    '../../../utils/ward-metadata': { async loadWardMetadata() { return {
      TEST: { province: 'Hà Nội', unitType: 'Xã' },
      WARD: { province: 'Hà Nội', unitType: 'Phường' },
      OTHER: { province: 'Tỉnh thử nghiệm', unitType: 'Xã' }
    }; } }
  });
  const invalid = await invoke(routes[0], { query: { year: '0' } });
  assert.equal(invalid.error.statusCode, 400);
  assert.equal(calls.length, 0);
  const valid = await invoke(routes[0], { query: { year: '2026' } });
  assert.equal(valid.error, undefined);
  assert.deepEqual(Array.from(calls[0]), ['2026-01-01', '2027-01-01']);
  assert.equal(valid.response.body.rows.length, 5);
  assert.equal(valid.response.body.rows[0].value, 0);
  assert.equal(valid.response.body.scope.unitType, 'Xã/Phường');
  assert.equal(valid.response.body.scope.basis, 'death-place');
});

test('hồ sơ không tồn tại trả 404', async () => {
  const routes = loadRoutes('modules/registrations/index.js', { async execute() { return [[]]; } });
  const lookup = routes.find(route => route.method === 'get' && route.path === '/:cccd');
  const result = await invoke(lookup, { params: { cccd: '001234567890' } });
  assert.equal(result.response.statusCode, 404);
});

test('ngày mất trước ngày sinh bị từ chối trước khi bắt đầu giao dịch', async () => {
  let transactions = 0;
  const routes = loadRoutes('modules/registrations/index.js', { getConnection() { transactions += 1; throw new Error('Không được truy cập DB'); } });
  const create = routes.find(route => route.method === 'post' && route.path === '/');
  const person = { name: 'Người thử nghiệm', birthDate: '2000-01-01', gender: 'Nam', hometown: 'Nơi thử', ethnicity: 'Kinh', phone: '0000000000' };
  const result = await invoke(create, { body: {
    deceased: { ...person, cccd: '001234567890', birthDate: '2027-01-01' },
    applicant: { ...person, cccd: '001234567891' },
    certificate: { id: 'GBT-TEST', issuedAt: '2026-11-09', deathAt: '2026-11-08T12:00', placeDetail: 'Nơi thử', causeDescription: 'Thử nghiệm', causeId: 'NN-TEST', wardId: 'XA-TEST', hospitalId: 'CS-TEST' },
    registration: { id: 'HS-TEST', registeredAt: '2026-11-09', relation: 'Người thân', officerId: 'CB-TEST' }
  } });
  assert.equal(result.error.statusCode, 400);
  assert.match(result.error.message, /Ngày sinh/);
  assert.equal(transactions, 0);
});
