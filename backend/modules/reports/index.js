const express = require('express');
const router = express.Router();

router.use('/gender', require('./gender'));
router.use('/areas', require('./areas'));
router.use('/age-causes', require('./age-causes'));
router.use('/hospitals', require('./hospitals'));
router.use('/years', require('./years'));

module.exports = router;
