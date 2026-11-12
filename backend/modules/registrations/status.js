const statuses = ['Đã duyệt', 'Chờ xử lý', 'Từ chối'];
const aliases = Object.freeze({
  'Đã duyệt': 'Đã duyệt',
  'Chờ xử lý': 'Chờ xử lý',
  'Từ chối': 'Từ chối',
  'Đã hoàn tất': 'Đã duyệt',
  'Đã tiếp nhận': 'Chờ xử lý',
  'Đang xử lý': 'Chờ xử lý',
  'Chờ duyệt': 'Chờ xử lý'
});
const normalizeStatus = value => typeof value === 'string' ? aliases[value.trim()] : undefined;
const statusSql = column => `CASE
  WHEN ${column} IN ('Đã duyệt', 'Đã hoàn tất') THEN 'Đã duyệt'
  WHEN ${column} IN ('Chờ xử lý', 'Đã tiếp nhận', 'Đang xử lý', 'Chờ duyệt') THEN 'Chờ xử lý'
  ELSE ${column} END`;
const normalizeRecord = record => ({ ...record, status: normalizeStatus(record.status) || record.status });

module.exports = { statuses, normalizeStatus, statusSql, normalizeRecord };
