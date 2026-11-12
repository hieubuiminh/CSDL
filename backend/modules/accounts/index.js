const express = require('express');
const crypto = require('crypto');
const { pool } = require('../../config/database');
const { asyncRoute, required } = require('../../utils/http');
const { adminOnly } = require('../../middleware/auth');
const { buildCredential, validateRecovery, invitations, requireStaffOfficer } = require('../../utils/auth');

const router = express.Router();
router.use(adminOnly);

router.get('/users', asyncRoute(async (_req, res) => {
  const [users] = await pool.query(`SELECT u.Id AS id, u.Username AS username, u.DisplayName AS name,
    u.Role AS role, u.CreatedAt AS createdAt, u.MaCanBo AS officerId, cb.HoTen AS officerName
    FROM App_User u LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo ORDER BY u.Role, u.Username`);
  res.json(users);
}));

router.post('/users', asyncRoute(async (req, res) => {
  const body = req.body;
  if (required(body, ['username', 'password', 'displayName', 'securityQuestion', 'securityAnswer']).length) {
    return res.status(400).json({ error: 'Hãy nhập họ tên, tên đăng nhập, mật khẩu và câu hỏi khôi phục.' });
  }
  const username = String(body.username).trim();
  const displayName = String(body.displayName).trim();
  const role = body.role ?? 'staff';
  if (!['admin', 'staff'].includes(role)) return res.status(400).json({ error: 'Vai trò phải là ADMIN hoặc Cán bộ.' });
  if (!/^[\p{L}\p{N}_.-]{3,40}$/u.test(username)) return res.status(400).json({ error: 'Tên đăng nhập cần dài 3–40 ký tự, chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.' });
  if (!displayName || displayName.length > 160) return res.status(400).json({ error: 'Họ tên cần từ 1 đến 160 ký tự.' });
  if (String(body.password).length < 10) return res.status(400).json({ error: 'Mật khẩu cần có ít nhất 10 ký tự.' });
  const recovery = validateRecovery(body);
  if (!recovery) return res.status(400).json({ error: 'Chọn câu hỏi khôi phục và nhập câu trả lời dài 3–120 ký tự.' });
  const officerId = role === 'staff' ? await requireStaffOfficer(pool, body.officerId) : null;
  const credential = await buildCredential(body.password, recovery.questionId, recovery.answer);
  try {
    await pool.execute('INSERT INTO App_User (Username,PasswordHash,DisplayName,Role,MaCanBo) VALUES (?,?,?,?,?)', [username, credential, displayName, role, officerId]);
  } catch (error) {
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Tên đăng nhập hoặc cán bộ liên kết đã được sử dụng.' });
    if (error.code === 'ER_NO_REFERENCED_ROW_2') return res.status(409).json({ error: 'Cán bộ liên kết không còn tồn tại. Hãy chọn lại cán bộ.' });
    throw error;
  }
  res.status(201).json({ ok: true, message: `Đã tạo tài khoản ${role === 'admin' ? 'ADMIN' : 'cán bộ'}.` });
}));

router.patch('/users/:id/role', asyncRoute(async (req, res) => {
  const id = String(req.params.id);
  const role = req.body.role;
  if (!/^[1-9]\d*$/.test(id) || !['admin', 'staff'].includes(role)) return res.status(400).json({ error: 'Tài khoản hoặc vai trò không hợp lệ.' });
  if (id === String(req.user.id) && role !== 'admin') return res.status(409).json({ error: 'Bạn không thể tự hạ quyền ADMIN của tài khoản đang đăng nhập.' });
  const connection = await pool.getConnection();
  try {
    await connection.beginTransaction();
    // Lock admin rows in a consistent order; simultaneous changes cannot remove every admin.
    const [admins] = await connection.query("SELECT Id FROM App_User WHERE Role='admin' ORDER BY Id FOR UPDATE");
    const [[target]] = await connection.execute('SELECT Id,Role,MaCanBo FROM App_User WHERE Id=? FOR UPDATE', [id]);
    if (!target) {
      await connection.rollback();
      return res.status(404).json({ error: 'Không tìm thấy tài khoản.' });
    }
    if (target.Role === 'admin' && role === 'staff' && admins.length <= 1) {
      await connection.rollback();
      return res.status(409).json({ error: 'Hệ thống phải còn ít nhất một ADMIN.' });
    }
    const officerId = role === 'staff'
      ? await requireStaffOfficer(connection, req.body.officerId ?? target.MaCanBo, id) : null;
    await connection.execute('UPDATE App_User SET Role=?,MaCanBo=? WHERE Id=?', [role, officerId, id]);
    await connection.commit();
    res.json({ ok: true, message: 'Đã cập nhật quyền tài khoản.' });
  } catch (error) {
    await connection.rollback();
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Cán bộ này đã được liên kết với một tài khoản khác.' });
    if (error.code === 'ER_NO_REFERENCED_ROW_2') return res.status(409).json({ error: 'Cán bộ liên kết không còn tồn tại. Hãy chọn lại cán bộ.' });
    throw error;
  } finally { connection.release(); }
}));

router.post('/invitations', asyncRoute(async (req, res) => {
  const officerId = await requireStaffOfficer(pool, req.body?.officerId);
  const now = Date.now();
  for (const [key, invite] of invitations) if (invite.expiresAt <= now || invite.used) invitations.delete(key);
  const code = crypto.randomBytes(5).toString('hex').toUpperCase();
  const expiresAt = now + 24 * 60 * 60 * 1000;
  invitations.set(code, { officerId, expiresAt, used: false });
  res.status(201).json({ code, officerId, expiresAt: new Date(expiresAt).toISOString() });
}));

module.exports = router;
