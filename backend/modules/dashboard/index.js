const express = require('express');
const { pool } = require('../../config/database');
const { asyncRoute } = require('../../utils/http');
const { registrationQuery } = require('../registrations/queries');
const { scopedReport } = require('../reports/queries');
const { recordScope } = require('../../utils/record-scope');
const { normalizeRecord } = require('../registrations/status');
const router = express.Router();

router.get('/', asyncRoute(async (req, res) => {
  const scope = recordScope(req);
  const [[cards]] = await pool.execute(`SELECT COUNT(*) AS total,
    SUM(CASE WHEN NgayDangKi >= DATE_FORMAT(CURDATE(), '%Y-%m-01')
      AND NgayDangKi < DATE_ADD(DATE_FORMAT(CURDATE(), '%Y-%m-01'), INTERVAL 1 MONTH) THEN 1 ELSE 0 END) AS thisMonth,
    SUM(CASE WHEN TrangThaiHoSo IN ('Đã duyệt', 'Đã hoàn tất') THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN TrangThaiHoSo IN ('Chờ xử lý', 'Chờ duyệt', 'Đã tiếp nhận', 'Đang xử lý') THEN 1 ELSE 0 END) AS active
    FROM Ho_So_Khai_Tu h WHERE 1=1${scope.sql}`, scope.params);
  const genderReport = scopedReport('gender', scope.officerId);
  const yearReport = scopedReport('years', scope.officerId);
  const [gender] = await pool.execute(genderReport.sql, genderReport.params);
  const [yearly] = await pool.execute(yearReport.sql, yearReport.params);
  const [recent] = await pool.execute(`${registrationQuery} WHERE 1=1${scope.sql} ORDER BY h.NgayDangKi DESC, h.SoGiayKhaiTu DESC LIMIT 6`, scope.params);
  res.json({
    cards: Object.fromEntries(Object.entries(cards).map(([key, value]) => [key, Number(value) || 0])),
    gender, yearly, recent: recent.map(normalizeRecord)
  });
}));

module.exports = router;
