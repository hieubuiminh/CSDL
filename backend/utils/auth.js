const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { secret } = require('../config/runtime');
const { badRequest } = require('./validation');

const signupAttempts = new Map();
const invitations = new Map();
const recoveryAttempts = new Map();
const securityQuestions = {
  first_street: 'Tên con đường đầu tiên bạn từng sống?',
  first_teacher: 'Tên giáo viên đầu tiên của bạn?',
  first_pet: 'Tên thú cưng đầu tiên của bạn?',
  favorite_dish: 'Món ăn bạn thường chọn trong dịp đặc biệt?'
};
// PasswordHash stores a versioned bundle; legacy bcrypt-only rows remain valid.
const recoveryParts = value => {
  if (!String(value || '').startsWith('recovery-v1|')) return { passwordHash: value, questionId: null, answerHash: null };
  const [, questionId, answerHash, passwordHash] = String(value).split('|');
  return { passwordHash, questionId, answerHash };
};
const recoveryConfigured = value => Boolean(recoveryParts(value).questionId && recoveryParts(value).answerHash);
const safeUser = user => ({
  id: user.Id,
  username: user.Username,
  name: user.DisplayName,
  role: user.Role || 'staff',
  officerId: user.Role === 'staff' ? user.LinkedOfficerId || user.MaCanBo || null : null,
  recoveryConfigured: Boolean(user.recoveryConfigured ?? recoveryConfigured(user.PasswordHash))
});
const issueToken = user => jwt.sign({
  id: user.Id,
  username: user.Username,
  name: user.DisplayName,
  role: user.Role || 'staff',
  recoveryConfigured: Boolean(user.recoveryConfigured ?? recoveryConfigured(user.PasswordHash))
}, secret, { expiresIn: '8h' });
const validUserBinding = user => Boolean(user && (user.Role === 'admin'
  || user.Role === 'staff' && typeof user.MaCanBo === 'string' && user.MaCanBo
    && typeof user.LinkedOfficerId === 'string' && user.LinkedOfficerId));

async function requireStaffOfficer(database, value, excludedUserId = 0) {
  if (typeof value !== 'string' || !value.trim() || [...value.trim()].length > 20) {
    throw badRequest('Hãy chọn cán bộ tiếp nhận liên kết với tài khoản cán bộ.');
  }
  const officerId = value.trim();
  const [[officer]] = await database.execute('SELECT MaCanBo FROM Can_Bo WHERE MaCanBo=? LIMIT 1', [officerId]);
  if (!officer) throw badRequest('Cán bộ tiếp nhận được chọn không tồn tại.');
  const [[linked]] = await database.execute('SELECT Id FROM App_User WHERE MaCanBo=? AND Id<>? LIMIT 1', [officerId, excludedUserId]);
  if (linked) throw Object.assign(new Error('Cán bộ này đã được liên kết với một tài khoản khác.'), { statusCode: 409 });
  return officer.MaCanBo;
}
const normalizeAnswer = value => String(value || '').normalize('NFKC').trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN');

function recentAttempts(map, key) {
  const now = Date.now();
  const active = (map.get(key) || []).filter(time => now - time < 15 * 60 * 1000);
  if (active.length >= 10) { map.set(key, active); return null; }
  active.push(now);
  map.set(key, active);
  return active;
}

function validateRecovery(body) {
  const questionId = String(body.securityQuestion || '');
  const answer = normalizeAnswer(body.securityAnswer);
  if (!securityQuestions[questionId] || answer.length < 3 || answer.length > 120) return null;
  return { questionId, answer };
}

async function buildCredential(password, questionId, answer, existingAnswerHash) {
  const answerHash = existingAnswerHash || await bcrypt.hash(normalizeAnswer(answer), 12);
  const passwordHash = await bcrypt.hash(String(password), 12);
  return `recovery-v1|${questionId}|${answerHash}|${passwordHash}`;
}

async function verifyCredential(password, storedValue) {
  const { passwordHash } = recoveryParts(storedValue);
  return Boolean(passwordHash && await bcrypt.compare(String(password || ''), passwordHash));
}

async function verifyRecovery(questionId, answer, storedValue) {
  const parts = recoveryParts(storedValue);
  if (!parts.questionId || !parts.answerHash || parts.questionId !== questionId) return false;
  return bcrypt.compare(normalizeAnswer(answer), parts.answerHash);
}

module.exports = {
  signupAttempts, invitations, recoveryAttempts, securityQuestions,
  recoveryParts, recoveryConfigured, safeUser, issueToken, normalizeAnswer,
  recentAttempts, validateRecovery, buildCredential, verifyCredential, verifyRecovery,
  validUserBinding, requireStaffOfficer
};
