const jwt = require('jsonwebtoken');
const { secret } = require('../config/runtime');
const { pool } = require('../config/database');
const { asyncRoute } = require('../utils/http');
const { validUserBinding } = require('../utils/auth');

const auth = asyncRoute(async (req, res, next) => {
  const token = req.cookies.session;
  if (!token) return res.status(401).json({ error: 'Vui lòng đăng nhập để tiếp tục.' });
  let claims;
  try {
    claims = jwt.verify(token, secret);
  } catch {
    res.clearCookie('session');
    return res.status(401).json({ error: 'Phiên đăng nhập đã hết hạn.' });
  }
  // Read the current role on every request so permission changes take effect immediately.
  const [[user]] = await pool.execute(`SELECT u.Id, u.Username, u.DisplayName, u.Role, u.MaCanBo,
    cb.MaCanBo AS LinkedOfficerId FROM App_User u
    LEFT JOIN Can_Bo cb ON cb.MaCanBo=u.MaCanBo WHERE u.Id=? LIMIT 1`, [claims.id]);
  if (!user || !['admin', 'staff'].includes(user.Role)) {
    res.clearCookie('session');
    return res.status(401).json({ error: 'Tài khoản không còn quyền truy cập. Hãy đăng nhập lại.' });
  }
  if (!validUserBinding(user)) return res.status(403).json({ error: 'Tài khoản cán bộ chưa được liên kết hợp lệ. Hãy nhờ ADMIN chọn cán bộ tiếp nhận.' });
  req.user = { id: user.Id, username: user.Username, name: user.DisplayName, role: user.Role,
    officerId: user.Role === 'staff' ? user.LinkedOfficerId : null };
  next();
});

const allowRoles = (...roles) => (req, res, next) => roles.includes(req.user?.role)
  ? next()
  : res.status(403).json({ error: 'Bạn không có quyền thực hiện chức năng này.' });
const adminOnly = allowRoles('admin');

module.exports = { auth, adminOnly, allowRoles };
