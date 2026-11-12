const express = require('express');
const helmet = require('helmet');
const cookieParser = require('cookie-parser');
const path = require('path');
const { pool } = require('./config/database');
const { asyncRoute } = require('./utils/http');
const { errorHandler } = require('./middleware/error-handler');

const app = express();
app.use(helmet({ contentSecurityPolicy: { directives: { defaultSrc: ["'self'"], styleSrc: ["'self'", "'unsafe-inline'"], fontSrc: ["'self'"], scriptSrc: ["'self'", "'unsafe-inline'"], imgSrc: ["'self'", 'data:'] } } }));
app.use(express.json({ limit: '100kb' }));
app.use(cookieParser());
app.use(express.static(path.join(__dirname, '..', 'public')));
app.get('/api/health', asyncRoute(async (_req, res) => {
  await pool.query('SELECT 1');
  res.json({ ok: true, database: true });
}));
app.use('/api', require('./modules'));
app.use('/api', (_req, res) => res.status(404).json({ error: 'Không tìm thấy chức năng API.' }));
app.get('*', (_req, res) => res.sendFile(path.join(__dirname, '..', 'public', 'index.html')));
app.use(errorHandler);

module.exports = app;
