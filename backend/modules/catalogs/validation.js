const { badRequest, objectValue, textValue } = require('../../utils/validation');
const { validCccd } = require('../registrations/validation');
const unitTypes = ['Xã', 'Phường', 'Đặc khu'];

function validateWardMetadata(input) {
  const body = objectValue(input);
  const province = textValue(body, 'province', 'tỉnh/thành phố', 100);
  const unitType = textValue(body, 'unitType', 'loại đơn vị', 20);
  if (!unitTypes.includes(unitType)) throw badRequest('Loại đơn vị phải là Xã, Phường hoặc Đặc khu.');
  return { province, unitType };
}

function validateCatalog(type, input) {
  const body = objectValue(input);
  const nameLimits = { cause: 150, hospital: 150, ward: 100, office: 150, officer: 100 };
  if (!Object.hasOwn(nameLimits, type)) throw Object.assign(new Error('Danh mục không hợp lệ.'), { statusCode: 404 });
  const data = {
    id: textValue(body, 'id', 'mã danh mục', 20),
    name: textValue(body, 'name', 'tên danh mục', nameLimits[type])
  };
  if (type === 'hospital' || type === 'office') data.address = textValue(body, 'address', 'địa chỉ', 255);
  if (['hospital', 'office', 'officer'].includes(type)) data.phone = textValue(body, 'phone', 'số điện thoại', 15);
  if (type === 'office') {
    data.level = textValue(body, 'level', 'cấp hành chính', 50);
    if (!['Xã','Phường'].includes(data.level)) throw badRequest('Cấp hành chính phải là Xã hoặc Phường.');
  }
  if (type === 'officer') {
    data.identity = textValue(body, 'identity', 'CCCD cán bộ', 12);
    if (!validCccd(data.identity)) throw badRequest('CCCD cán bộ phải gồm đúng 12 chữ số.');
    data.role = textValue(body, 'role', 'chức vụ cán bộ', 100);
    data.officeId = textValue(body, 'officeId', 'mã UBND công tác', 20);
  }
  if (type === 'ward' && (body.province || body.unitType)) Object.assign(data, validateWardMetadata(body));
  return data;
}

module.exports = { validateCatalog, validateWardMetadata };
