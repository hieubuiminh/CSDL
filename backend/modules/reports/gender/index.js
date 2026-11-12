const express = require('express');
const { pool } = require('../../../config/database');
const { asyncRoute } = require('../../../utils/http');
const { scopedReport } = require('../queries');
const { recordOfficerId } = require('../../../utils/record-scope');
const router = express.Router();
router.get('/', asyncRoute(async (req,res) => {
  const query = scopedReport('gender', recordOfficerId(req));
  const [rows] = await pool.execute(query.sql, query.params);
  res.json(rows);
}));
module.exports = router;
