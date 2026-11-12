const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { pool } = require('../../config/database');
const { secret, secureCookie, localAdminRecoveryEnabled, matchesSecret } = require('../../config/runtime');
const { asyncRoute, required } = require('../../utils/http');
const { auth } = require('../../middleware/auth');
const {
  signupAttempts, invitations, recoveryAttempts, securityQuestions,
  recoveryParts, recoveryConfigured, safeUser, issueToken, normalizeAnswer,
  recentAttempts, validateRecovery, buildCredential, verifyCredential, verifyRecovery,
  validUserBinding, requireStaffOfficer
} = require('../../utils/auth');

const router = express.Router();
// Public account setup, self-registration, login, logout and password reset.
router.get('/status', asyncRoute(async (_req, res) => {
  let total;
  try { [[{ total }]] = await pool.query("SELECT COUNT(*) AS total FROM App_User WHERE Role='admin'"); }
  catch (error) {
    if (error.code === 'ER_NO_SUCH_TABLE') return res.status(503).json({ error: 'Thiếu bảng tài khoản App_User. Hãy nạp database/app_setup.sql sau khi tạo cơ sở dữ liệu, rồi khởi động lại ứng dụng.' });
    if (['ER_ACCESS_DENIED_ERROR','ER_TABLEACCESS_DENIED_ERROR'].includes(error.code)) return res.status(503).json({ error: 'Tài khoản MySQL của ứng dụng chưa có quyền truy cập bảng. Kiểm tra DB_USER, DB_PASSWORD và quyền trên cơ sở dữ liệu.' });
    throw error;
  }
  let user = null;
  if (_req.cookies.session) {
    try {
      const claims = jwt.verify(_req.cookies.session, secret);
      const [rows] = await pool.execute(`SELECT u.Id, u.Username, u.DisplayName, u.Role, u.PasswordHash, u.MaCanBo,
        cb.MaCanBo AS LinkedOfficerId FROM App_User u
        LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Id=? LIMIT 1`, [claims.id]);
      if (validUserBinding(rows[0])) user = safeUser(rows[0]);
    } catch { /* expired session or deleted account */ }
  }
  let localAdminRecoveryAvailable = false;
  if (localAdminRecoveryEnabled) {
    const [admins] = await pool.query("SELECT PasswordHash FROM App_User WHERE Role='admin'");
    localAdminRecoveryAvailable = admins.some(admin => !recoveryConfigured(admin.PasswordHash));
  }
  res.json({ setupRequired: Number(total) === 0, user, localAdminRecoveryAvailable });
}));
router.post('/setup', asyncRoute(async (req, res) => {
  if (!secret || secret.length < 32) return res.status(503).json({ error: 'JWT_SECRET chưa được thiết lập hoặc ngắn hơn 32 ký tự. Hãy cập nhật cấu hình máy chủ rồi khởi động lại.' });
  const missing = required(req.body, ['username','password','displayName','securityQuestion','securityAnswer']);
  if (missing.length) return res.status(400).json({ error: 'Hãy điền họ tên, tên đăng nhập, mật khẩu và câu hỏi khôi phục.' });
  const username = String(req.body.username).trim(); const displayName = String(req.body.displayName).trim();
  if (!/^[\p{L}\p{N}_.-]{3,40}$/u.test(username)) return res.status(400).json({ error: 'Tên đăng nhập cần dài 3–40 ký tự.' });
  if (displayName.length > 160) return res.status(400).json({ error: 'Họ tên không được dài quá 160 ký tự.' });
  if (String(req.body.password).length < 10) return res.status(400).json({ error: 'Mật khẩu cần có ít nhất 10 ký tự.' });
  const recovery = validateRecovery(req.body);
  if (!recovery) return res.status(400).json({ error: 'Chọn câu hỏi khôi phục và nhập câu trả lời dài ít nhất 3 ký tự.' });
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();
    const [[{ total }]] = await conn.query("SELECT COUNT(*) AS total FROM App_User WHERE Role='admin' FOR UPDATE");
    if (Number(total) !== 0) { await conn.rollback(); return res.status(409).json({ error: 'Tài khoản ban đầu đã được tạo.' }); }
    const credential = await buildCredential(req.body.password, recovery.questionId, recovery.answer);
    const [result] = await conn.execute('INSERT INTO App_User (Username, PasswordHash, DisplayName, Role) VALUES (?, ?, ?, ?)', [username, credential, displayName, 'admin']);
    const user = { Id: result.insertId, Username: username, DisplayName: displayName, Role: 'admin', MaCanBo: null, PasswordHash: credential };
    const token = issueToken(user);
    await conn.commit();
    res.cookie('session', token, { httpOnly: true, sameSite: 'strict', secure: secureCookie, maxAge: 8 * 60 * 60 * 1000 });
    res.status(201).json({ user: safeUser(user) });
  } catch (error) {
    await conn.rollback();
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Tên đăng nhập đã tồn tại. Hãy chọn tên khác.' });
    throw error;
  } finally { conn.release(); }
}));
router.get('/security-questions', (_req, res) => res.json(securityQuestions));
router.post('/recovery-question', asyncRoute(async (req, res) => {
  const key = req.ip || req.socket.remoteAddress || 'local';
  if (!recentAttempts(recoveryAttempts, key)) return res.status(429).json({ error: 'Bạn đã thử quá nhiều lần. Hãy thử lại sau 15 phút.' });
  const username = String(req.body.username || '').trim();
  const [users] = await pool.execute('SELECT Role, PasswordHash FROM App_User WHERE Username=? LIMIT 1', [username]);
  const user = users[0];
  const parts = recoveryParts(user?.PasswordHash);
  if (!parts.questionId || !securityQuestions[parts.questionId]) return res.status(404).json({ error: 'Tài khoản chưa có câu hỏi khôi phục. Hãy nhờ người vận hành máy chủ hỗ trợ.' });
  res.json({
    questionId: parts.questionId || '',
    question: securityQuestions[parts.questionId] || '',
    hasConfiguredQuestion: Boolean(parts.questionId && securityQuestions[parts.questionId]),
    allowAdminNameFallback: false
  });
}));
// External registration is allowed only with an unused, admin-issued invite.
router.post('/register', asyncRoute(async (req, res) => {
  const [[{ admins }]] = await pool.query("SELECT COUNT(*) AS admins FROM App_User WHERE Role='admin'");
  if (Number(admins) === 0) return res.status(403).json({ error: 'Quản trị viên cần tạo tài khoản đầu tiên trước khi cán bộ đăng ký.' });
  const clientKey = req.ip || req.socket.remoteAddress || 'local';
  if (!recentAttempts(signupAttempts, clientKey)) return res.status(429).json({ error: 'Bạn đã thử đăng ký quá nhiều lần. Hãy thử lại sau 15 phút.' });
  const username = String(req.body.username || '').trim();
  const displayName = String(req.body.displayName || '').trim();
  const password = String(req.body.password || '');
  const code = String(req.body.inviteCode || '').trim().toUpperCase();
  const recovery = validateRecovery(req.body);
  if (!username || !displayName || !password || !code) return res.status(400).json({ error: 'Hãy nhập đủ thông tin và mã mời.' });
  if (!/^[\p{L}\p{N}_.-]{3,40}$/u.test(username)) return res.status(400).json({ error: 'Tên đăng nhập cần dài 3–40 ký tự, chỉ gồm chữ, số, dấu chấm, gạch dưới hoặc gạch ngang.' });
  if (displayName.length > 160) return res.status(400).json({ error: 'Họ tên không được dài quá 160 ký tự.' });
  if (password.length < 10) return res.status(400).json({ error: 'Mật khẩu cần có ít nhất 10 ký tự.' });
  if (!recovery) return res.status(400).json({ error: 'Chọn câu hỏi khôi phục và nhập câu trả lời dài ít nhất 3 ký tự.' });
  const invite = invitations.get(code);
  if (!invite || invite.used || invite.expiresAt <= Date.now()) return res.status(403).json({ error: 'Mã mời không hợp lệ, đã dùng hoặc đã hết hạn. Hãy liên hệ quản trị viên.' });
  invite.used = true;
  let credential, officerId;
  try {
    // Reserve the one-use invitation before awaiting DB/hash work, and use its server-owned identity.
    officerId = await requireStaffOfficer(pool, invite.officerId);
    credential = await buildCredential(password, recovery.questionId, recovery.answer);
  }
  catch (error) { invite.used = false; throw error; }
  try {
    await pool.execute('INSERT INTO App_User (Username,PasswordHash,DisplayName,Role,MaCanBo) VALUES (?,?,?,?,?)', [username, credential, displayName, 'staff', officerId]);
  } catch (error) {
    invite.used = false;
    if (error.code === 'ER_DUP_ENTRY') return res.status(409).json({ error: 'Tên đăng nhập hoặc cán bộ liên kết đã được sử dụng.' });
    if (error.code === 'ER_NO_REFERENCED_ROW_2') return res.status(409).json({ error: 'Cán bộ liên kết không còn tồn tại. Hãy nhờ ADMIN cấp mã mời mới.' });
    throw error;
  }
  res.status(201).json({ ok: true, message: 'Đăng ký thành công. Bạn có thể đăng nhập.' });
}));
router.post('/reset-password', asyncRoute(async (req, res) => {
  const key = req.ip || req.socket.remoteAddress || 'local';
  if (!recentAttempts(recoveryAttempts, key)) return res.status(429).json({ error: 'Bạn đã thử quá nhiều lần. Hãy thử lại sau 15 phút.' });
  const username = String(req.body.username || '').trim();
  const password = String(req.body.password || '');
  const questionId = String(req.body.securityQuestion || ''); const answer = String(req.body.securityAnswer || '');
  if (!username || password.length < 10) return res.status(400).json({ error: 'Nhập tên đăng nhập và mật khẩu mới có ít nhất 10 ký tự.' });
  const [users] = await pool.execute('SELECT Role, PasswordHash FROM App_User WHERE Username=? LIMIT 1', [username]);
  const user = users[0];
  const parts = recoveryParts(user?.PasswordHash);
  const configuredAnswerAccepted = user && await verifyRecovery(questionId, answer, user.PasswordHash);
  if (!configuredAnswerAccepted) return res.status(400).json({ error: 'Phương thức xác minh hoặc câu trả lời không chính xác. Hãy kiểm tra lại thông tin rồi thử lại.' });
  const credential = parts.questionId
    ? await buildCredential(password, parts.questionId, '', parts.answerHash)
    : await bcrypt.hash(password, 12);
  await pool.execute('UPDATE App_User SET PasswordHash=? WHERE Username=?', [credential, username]);
  res.json({ ok: true, message: 'Đã đổi mật khẩu. Hãy đăng nhập bằng mật khẩu mới.' });
}));
router.post('/local-admin-reset', asyncRoute(async (req, res) => {
  if (!localAdminRecoveryEnabled) return res.status(404).json({ error: 'Chức năng khôi phục quản trị viên chưa được bật.' });
  const key = req.ip || req.socket.remoteAddress || 'local';
  if (!recentAttempts(recoveryAttempts, key)) return res.status(429).json({ error: 'Bạn đã thử quá nhiều lần. Hãy thử lại sau 15 phút.' });
  const username = String(req.body.username || '').trim();
  const newPassword = String(req.body.newPassword || '');
  if (!username || newPassword.length < 10) return res.status(400).json({ error: 'Nhập tên quản trị viên và mật khẩu mới có ít nhất 10 ký tự.' });
  const [admins] = await pool.execute("SELECT Id,Role,PasswordHash FROM App_User WHERE Username=? AND Role='admin' LIMIT 1", [username]);
  const admin = admins[0];
  if (!admin || recoveryConfigured(admin.PasswordHash) || !matchesSecret(req.body.recoveryToken, process.env.ADMIN_RECOVERY_TOKEN)) {
    return res.status(403).json({ error: 'Không thể khôi phục tài khoản. Hãy kiểm tra mã dự phòng hoặc dùng câu hỏi khôi phục đã thiết lập.' });
  }
  const credential = await bcrypt.hash(newPassword, 12);
  await pool.execute('UPDATE App_User SET PasswordHash=? WHERE Id=?', [credential, admin.Id]);
  res.json({ ok: true, message: 'Đã đặt lại mật khẩu. Đăng nhập rồi thiết lập câu hỏi khôi phục trong menu tài khoản.' });
}));
router.post('/login', asyncRoute(async (req, res) => {
  if (!secret || secret.length < 32) return res.status(503).json({ error: 'JWT_SECRET chưa được thiết lập hoặc ngắn hơn 32 ký tự. Hãy cập nhật cấu hình máy chủ rồi khởi động lại.' });
  const [rows] = await pool.execute(`SELECT u.*, cb.MaCanBo AS LinkedOfficerId FROM App_User u
    LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Username=?`, [String(req.body.username || '').trim()]);
  if (!rows.length || !(await verifyCredential(req.body.password, rows[0].PasswordHash))) return res.status(401).json({ error: 'Tên đăng nhập hoặc mật khẩu chưa đúng.' });
  if (!validUserBinding(rows[0])) return res.status(403).json({ error: 'Tài khoản cán bộ chưa được liên kết hợp lệ. Hãy nhờ ADMIN chọn cán bộ tiếp nhận.' });
  res.cookie('session', issueToken(rows[0]), { httpOnly: true, sameSite: 'strict', secure: secureCookie, maxAge: 8 * 60 * 60 * 1000 });
  res.json({ user: safeUser(rows[0]) });
}));
router.post('/logout', (_req, res) => { res.clearCookie('session', { httpOnly: true, sameSite: 'strict', secure: secureCookie }); res.json({ ok: true }); });


router.post('/recovery-setup', auth, asyncRoute(async (req, res) => {
  const currentPassword = String(req.body.currentPassword || ''); const recovery = validateRecovery(req.body);
  if (!currentPassword || !recovery) return res.status(400).json({ error: 'Nhập mật khẩu hiện tại, chọn câu hỏi và câu trả lời khôi phục.' });
  const [[user]] = await pool.execute('SELECT * FROM App_User WHERE Id=?', [req.user.id]);
  if (!user || !await verifyCredential(currentPassword, user.PasswordHash)) return res.status(401).json({ error: 'Mật khẩu hiện tại chưa đúng.' });
  const credential = await buildCredential(currentPassword, recovery.questionId, recovery.answer);
  await pool.execute('UPDATE App_User SET PasswordHash=? WHERE Id=?', [credential, req.user.id]);
  const updated = { ...user, LinkedOfficerId: req.user.officerId, PasswordHash: credential };
  res.cookie('session', issueToken(updated), { httpOnly:true, sameSite:'strict', secure:secureCookie, maxAge:8 * 60 * 60 * 1000 });
  res.json({ user: safeUser(updated) });
}));

router.post('/change-password', auth, asyncRoute(async (req, res) => {
  const currentPassword = String(req.body.currentPassword || '');
  const newPassword = String(req.body.newPassword || '');
  if (!currentPassword || newPassword.length < 10) return res.status(400).json({ error: 'Nhập mật khẩu hiện tại và mật khẩu mới có ít nhất 10 ký tự.' });
  const [[user]] = await pool.execute('SELECT * FROM App_User WHERE Id=? LIMIT 1', [req.user.id]);
  if (!user || !await verifyCredential(currentPassword, user.PasswordHash)) return res.status(401).json({ error: 'Mật khẩu hiện tại chưa đúng.' });
  const parts = recoveryParts(user.PasswordHash);
  const passwordHash = await bcrypt.hash(newPassword, 12);
  const credential = parts.questionId && parts.answerHash
    ? `recovery-v1|${parts.questionId}|${parts.answerHash}|${passwordHash}`
    : passwordHash;
  await pool.execute('UPDATE App_User SET PasswordHash=? WHERE Id=?', [credential, req.user.id]);
  const updated = { ...user, LinkedOfficerId: req.user.officerId, PasswordHash: credential };
  res.cookie('session', issueToken(updated), { httpOnly:true, sameSite:'strict', secure:secureCookie, maxAge:8 * 60 * 60 * 1000 });
  res.json({ user: safeUser(updated) });
}));


module.exports = router;
