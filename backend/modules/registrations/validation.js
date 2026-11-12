const { badRequest, objectValue, textValue } = require('../../utils/validation');
const { statuses, normalizeStatus } = require('./status');
const validCccd = value => typeof value === 'string' && /^\d{12}$/.test(value);

function validDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [year, month, day] = value.split('-').map(Number);
  if (year < 1000 || year > 9999 || month < 1 || month > 12 || day < 1 || day > 31) return false;
  const date = new Date(Date.UTC(year, month - 1, day));
  return date.getUTCFullYear() === year && date.getUTCMonth() === month - 1 && date.getUTCDate() === day;
}

function validDateTime(value) {
  if (typeof value !== 'string') return false;
  const match = value.match(/^(\d{4}-\d{2}-\d{2})[T ](\d{2}):(\d{2})(?::(\d{2}))?$/);
  return Boolean(match && validDate(match[1]) && Number(match[2]) <= 23
    && Number(match[3]) <= 59 && (match[4] === undefined || Number(match[4]) <= 59));
}

function validatePerson(input, label) {
  const person = objectValue(input);
  const output = {
    cccd: textValue(person, 'cccd', `CCCD ${label}`, 12),
    name: textValue(person, 'name', `họ tên ${label}`, 100),
    birthDate: textValue(person, 'birthDate', `ngày sinh ${label}`, 10),
    gender: textValue(person, 'gender', `giới tính ${label}`, 4),
    hometown: textValue(person, 'hometown', `quê quán ${label}`, 255, { optional: true }),
    ethnicity: textValue(person, 'ethnicity', `dân tộc ${label}`, 50, { optional: true, defaultValue: 'Kinh' }),
    phone: textValue(person, 'phone', `số điện thoại ${label}`, 15, { optional: true })
  };
  if (!validCccd(output.cccd)) throw badRequest(`CCCD ${label} phải gồm đúng 12 chữ số.`);
  if (!['Nam', 'Nữ', 'Khác'].includes(output.gender)) throw badRequest(`Giới tính ${label} phải là Nam, Nữ hoặc Khác.`);
  if (!validDate(output.birthDate)) throw badRequest(`Ngày sinh ${label} không hợp lệ.`);
  return output;
}

function validateRegistration(input) {
  const body = objectValue(input);
  const deceased = validatePerson(body.deceased, 'người mất');
  const applicant = validatePerson(body.applicant, 'người đăng ký');
  if (deceased.cccd === applicant.cccd) throw badRequest('Người khai tử phải khác người đã mất.');
  const certificateInput = objectValue(body.certificate);
  const certificate = {
    id: textValue(certificateInput, 'id', 'số giấy báo tử', 20),
    issuedAt: textValue(certificateInput, 'issuedAt', 'ngày cấp giấy báo tử', 10),
    deathAt: textValue(certificateInput, 'deathAt', 'ngày giờ mất', 19),
    placeDetail: textValue(certificateInput, 'placeDetail', 'nơi mất chi tiết', 255, { optional: true }),
    causeDescription: textValue(certificateInput, 'causeDescription', 'mô tả nguyên nhân', null, { optional: true, maxBytes: 65535 }),
    causeId: textValue(certificateInput, 'causeId', 'mã nguyên nhân', 20),
    wardId: textValue(certificateInput, 'wardId', 'mã xã/phường', 20),
    hospitalId: textValue(certificateInput, 'hospitalId', 'mã cơ sở y tế', 20)
  };
  const registrationInput = objectValue(body.registration);
  const rawStatus = textValue(registrationInput, 'status', 'trạng thái hồ sơ', 30, { optional: true, defaultValue: 'Chờ xử lý' });
  const registration = {
    id: textValue(registrationInput, 'id', 'số giấy khai tử', 20),
    registeredAt: textValue(registrationInput, 'registeredAt', 'ngày đăng ký', 10),
    relation: textValue(registrationInput, 'relation', 'quan hệ với người mất', 50),
    officerId: textValue(registrationInput, 'officerId', 'mã cán bộ tiếp nhận', 20),
    status: normalizeStatus(rawStatus)
  };
  if (!registration.status) throw badRequest('Trạng thái hồ sơ không hợp lệ.');
  if (!validDate(certificate.issuedAt) || !validDate(registration.registeredAt) || !validDateTime(certificate.deathAt)) throw badRequest('Ngày tháng hoặc giờ mất không hợp lệ.');
  const deathDate = certificate.deathAt.slice(0, 10);
  if (deathDate > certificate.issuedAt || certificate.issuedAt > registration.registeredAt) throw badRequest('Ngày mất ≤ ngày cấp giấy báo tử ≤ ngày đăng ký khai tử.');
  if (deceased.birthDate > deathDate) throw badRequest('Ngày sinh của người mất không thể sau ngày mất.');
  if (applicant.birthDate > registration.registeredAt) throw badRequest('Ngày sinh của người đăng ký không thể sau ngày đăng ký.');
  certificate.deathAt = certificate.deathAt.replace('T', ' ');
  if (certificate.deathAt.length === 16) certificate.deathAt += ':00';
  let burial = null;
  const burialInput = objectValue(body.burial);
  if (Object.values(burialInput).some(value => value !== undefined && value !== null && String(value).trim() !== '')) {
    burial = {
      id: textValue(burialInput, 'id', 'mã an táng', 30),
      form: textValue(burialInput, 'form', 'hình thức an táng', 50),
      cemetery: textValue(burialInput, 'cemetery', 'tên nghĩa trang hoặc đài hóa thân', 150),
      date: textValue(burialInput, 'date', 'ngày an táng', 10)
    };
    if (!['Hỏa táng', 'Địa táng'].includes(burial.form)) throw badRequest('Hình thức an táng phải là Hỏa táng hoặc Địa táng.');
    if (!validDate(burial.date)) throw badRequest('Ngày an táng không hợp lệ.');
    if (burial.date < deathDate) throw badRequest('Ngày an táng không thể trước ngày mất.');
  }
  return { deceased, applicant, certificate, registration, burial };
}

module.exports = { validDate, validDateTime, validCccd, statuses, validatePerson, validateRegistration };
