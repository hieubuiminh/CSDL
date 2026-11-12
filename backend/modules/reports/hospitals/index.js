const express = require('express');
const { pool } = require('../../../config/database');
const { asyncRoute } = require('../../../utils/http');
const { previousQuarter } = require('../helpers');
const { scopedReport } = require('../queries');
const { recordOfficerId } = require('../../../utils/record-scope');
const router = express.Router();
router.get('/', asyncRoute(async (req,res) => {
  const officerId = recordOfficerId(req);
  const period = previousQuarter();
  const query = scopedReport('hospitals', officerId, [period.start,period.end]);
  const [rows] = await pool.execute(query.sql, query.params);
  res.json({period,rows});
}));
module.exports = router;
