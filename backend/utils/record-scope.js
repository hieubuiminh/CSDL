const forbidden = message => Object.assign(new Error(message), { statusCode: 403 });

// The caller must use the identity refreshed from App_User by the auth middleware.
// Never derive the receiving officer from URL parameters, form fields or JWT claims.
function recordOfficerId(req) {
  if (req.user?.role === 'admin') return null;
  if (req.user?.role === 'staff' && typeof req.user.officerId === 'string' && req.user.officerId.trim()) {
    return req.user.officerId;
  }
  throw forbidden('Tài khoản chưa được liên kết với cán bộ tiếp nhận.');
}

function recordScope(req, alias = 'h') {
  const officerId = recordOfficerId(req);
  return { officerId, sql: officerId ? ` AND ${alias}.MaCanBoTiepNhan=?` : '', params: officerId ? [officerId] : [] };
}

module.exports = { recordOfficerId, recordScope, forbidden };
