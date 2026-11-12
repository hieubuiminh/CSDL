// Compatibility entry point for the former combined admin router.
const express = require('express');
const router = express.Router();
router.use(require('../modules/catalogs'));
router.use(require('../modules/accounts'));
module.exports = router;
