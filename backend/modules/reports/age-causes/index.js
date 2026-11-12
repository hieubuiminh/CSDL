const express = require('express');
const { pool } = require('../../../config/database');
const { asyncRoute } = require('../../../utils/http');
const { summarizeAgeCauses } = require('../helpers');
const { scopedReport } = require('../queries');
const { recordOfficerId } = require('../../../utils/record-scope');
const router = express.Router();
router.get('/', asyncRoute(async (req,res) => {
  const query = scopedReport('ageCauses', recordOfficerId(req));
  const [rows] = await pool.execute(query.sql, query.params);
  res.json(summarizeAgeCauses(rows));
}));
module.exports = router;
