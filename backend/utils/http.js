const asyncRoute = fn => (req, res, next) => Promise.resolve(fn(req, res, next)).catch(next);
const required = (obj, fields) => fields.filter(key => obj[key] === undefined || obj[key] === null || String(obj[key]).trim() === '');
const localDate = value => /^\d{4}-\d{2}-\d{2}$/.test(String(value || ''));

module.exports = { asyncRoute, required, localDate };