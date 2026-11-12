// Compatibility entry point. Each report has its own index module.
const express = require('express');
const router = express.Router();
router.use('/reports', require('../modules/reports'));
module.exports = router;
