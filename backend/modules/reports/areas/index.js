const express = require('express');
const { pool } = require('../../../config/database');
const { asyncRoute } = require('../../../utils/http');
const { parseYear } = require('../helpers');
const { scopedReport } = require('../queries');
const { recordOfficerId } = require('../../../utils/record-scope');
const router = express.Router();
router.get('/', asyncRoute(async (req,res) => {
  const officerId = recordOfficerId(req);
  const year = parseYear(req.query.year);
  const query = scopedReport('areas', officerId, [`${year}-01-01`, `${year+1}-01-01`]);
  const [rows] = await pool.execute(query.sql, query.params);
  res.json({ year,rows,scope:{basis:'death-place',province:'Hà Nội',unitType:'Xã/Phường'} });
}));
module.exports = router;
