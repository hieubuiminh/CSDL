// Compatibility entry point for the former combined registration router.
const express = require('express');
const router = express.Router();
router.use('/dashboard', require('../modules/dashboard'));
router.use('/registrations', require('../modules/registrations'));
module.exports = router;
