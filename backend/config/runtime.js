const crypto = require('crypto');

const secret = process.env.JWT_SECRET || (process.env.NODE_ENV === 'production' ? null : 'local-development-secret-change-before-deployment');
const secureCookie = process.env.COOKIE_SECURE === 'true' || (process.env.COOKIE_SECURE !== 'false' && process.env.NODE_ENV === 'production');
const localAdminRecoveryEnabled = process.env.ALLOW_LOCAL_PASSWORD_RESET === 'true' && String(process.env.ADMIN_RECOVERY_TOKEN || '').length >= 32;
const matchesSecret = (provided, expected) => {
  const actual = Buffer.from(String(provided || ''));
  const configured = Buffer.from(String(expected || ''));
  return actual.length > 0 && actual.length === configured.length && crypto.timingSafeEqual(actual, configured);
};

module.exports = {
  secret,
  secureCookie,
  localAdminRecoveryEnabled,
  matchesSecret
};
