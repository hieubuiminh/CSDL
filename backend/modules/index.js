const express = require('express');
const { auth, allowRoles } = require('../middleware/auth');

const router = express.Router();
router.use('/auth', require('./auth'));
router.use(auth, allowRoles('admin', 'staff'));
router.use('/dashboard', require('./dashboard'));
router.use('/registrations', require('./registrations'));
router.use('/reports', require('./reports'));
router.use(require('./catalogs'));
router.use(require('./accounts'));

module.exports = router;
