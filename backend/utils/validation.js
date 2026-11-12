const badRequest = message => Object.assign(new Error(message), { statusCode: 400 });
const objectValue = value => value && typeof value === 'object' && !Array.isArray(value) ? value : {};

function textValue(object, key, label, maxLength, { optional = false, defaultValue = '', maxBytes } = {}) {
  const value = object[key];
  if (value === undefined || value === null || value === '') {
    if (optional) return defaultValue;
    throw badRequest(`Hãy nhập ${label}.`);
  }
  if (typeof value !== 'string') throw badRequest(`${label} phải là chuỗi ký tự.`);
  const text = value.trim();
  if (!text) {
    if (optional) return defaultValue;
    throw badRequest(`Hãy nhập ${label}.`);
  }
  if (maxLength && [...text].length > maxLength) throw badRequest(`${label} không được dài quá ${maxLength} ký tự.`);
  if (maxBytes && Buffer.byteLength(text, 'utf8') > maxBytes) throw badRequest(`${label} vượt quá dung lượng cho phép.`);
  return text;
}

// Legacy databases may have narrower VARCHAR columns and permissive SQL mode.
// Strict writes fail rather than silently truncating text or converting enums.
async function strictWrites(connection) {
  await connection.execute(`SET SESSION sql_mode = IF(
    FIND_IN_SET('STRICT_TRANS_TABLES', @@SESSION.sql_mode) OR FIND_IN_SET('STRICT_ALL_TABLES', @@SESSION.sql_mode),
    @@SESSION.sql_mode, CONCAT_WS(',', NULLIF(@@SESSION.sql_mode, ''), 'STRICT_TRANS_TABLES'))`);
}

module.exports = { badRequest, objectValue, textValue, strictWrites };
