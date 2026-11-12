const AGE_GROUPS = ['Dưới 18', '18–60', 'Trên 60'];

function parseYear(value, now = new Date()) {
  if (value === undefined || value === '') {
    return Number(new Intl.DateTimeFormat('en', { timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric' }).format(now));
  }
  if (typeof value !== 'string' || !/^\d{4}$/.test(value) || Number(value) < 1000 || Number(value) > 9998) {
    throw Object.assign(new Error('Năm thống kê phải là số có 4 chữ số, từ 1000 đến 9998.'), { statusCode: 400 });
  }
  return Number(value);
}

function previousQuarter(now = new Date()) {
  const parts = new Intl.DateTimeFormat('en', {
    timeZone: 'Asia/Ho_Chi_Minh', year: 'numeric', month: 'numeric'
  }).formatToParts(now);
  const year = Number(parts.find(part => part.type === 'year').value);
  const month = Number(parts.find(part => part.type === 'month').value);
  const currentQuarter = Math.floor((month - 1) / 3);
  const end = new Date(Date.UTC(year, currentQuarter * 3, 1));
  const start = new Date(Date.UTC(year, currentQuarter * 3 - 3, 1));
  return {
    start: start.toISOString().slice(0, 10),
    end: end.toISOString().slice(0, 10),
    label: `Quý ${Math.floor(start.getUTCMonth() / 3) + 1}/${start.getUTCFullYear()}`,
    timeZone: 'Asia/Ho_Chi_Minh'
  };
}

function summarizeAgeCauses(records) {
  let invalidCount = 0;
  let unknownCount = 0;
  const groups = new Map(AGE_GROUPS.map(ageGroup => [ageGroup, new Map()]));
  for (const record of records) {
    const value = Number(record.value) || 0;
    if (record.ageGroup === '__invalid__') { invalidCount += value; continue; }
    if (!groups.has(record.ageGroup)) { unknownCount += value; continue; }
    const causes = groups.get(record.ageGroup);
    const cause = record.cause || 'Chưa rõ nguyên nhân';
    causes.set(cause, (causes.get(cause) || 0) + value);
  }
  return {
    rows: AGE_GROUPS.map(ageGroup => {
      const causes = [...groups.get(ageGroup)].map(([cause, value]) => ({ cause, value }))
        .sort((a, b) => b.value - a.value || a.cause.localeCompare(b.cause, 'vi'));
      const highest = causes[0]?.value || 0;
      return {
        ageGroup,
        total: causes.reduce((total, cause) => total + cause.value, 0),
        commonCauses: causes.filter(cause => highest > 0 && cause.value === highest),
        causes
      };
    }),
    invalidCount,
    unknownCount,
    basis: 'Tuổi tại thời điểm mất; chỉ hồ sơ đã duyệt.'
  };
}

module.exports = { AGE_GROUPS, parseYear, previousQuarter, summarizeAgeCauses };
