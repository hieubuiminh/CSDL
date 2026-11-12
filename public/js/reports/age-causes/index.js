import { $, api, esc, num } from '../../shared.js';
import { reportTable, setLoading, setReportError } from '../shared.js';

const groups = ['Dưới 18', '18–60', 'Trên 60'];

export async function loadAgeCauseReport() {
  const ids = ['ageReportSummary', 'ageReport']; setLoading(ids);
  try {
    const result = await api('/api/reports/age-causes');
    const rows = groups.map(ageGroup => result.rows.find(row => row.ageGroup === ageGroup) || { ageGroup, total: 0, commonCauses: [], causes: [] });
    $('#ageReportSummary').innerHTML = rows.map(row => `<article class="panel age-summary-card"><span class="eyebrow">${esc(row.ageGroup)} TUỔI</span><strong class="age-summary-total">${num(row.total)} <small>người</small></strong><h2>Nguyên nhân phổ biến nhất</h2>${row.commonCauses.length ? `<ul class="common-causes">${row.commonCauses.map(cause => `<li><span>${esc(cause.cause)}</span><strong>${num(cause.value)} người</strong></li>`).join('')}</ul>` : '<p class="report-note">Chưa có dữ liệu trong nhóm tuổi này.</p>'}</article>`).join('');
    const detail = rows.flatMap(row => row.causes.length ? row.causes.map(cause => [row.ageGroup, cause.cause, num(cause.value), row.commonCauses.some(common => common.cause === cause.cause) ? 'Phổ biến nhất' : '']) : [[row.ageGroup, 'Chưa có dữ liệu', '0', '']]);
    $('#ageReport').innerHTML = reportTable(['Nhóm tuổi', 'Nguyên nhân tử vong', 'Số người', 'Ghi chú'], detail);
    const omitted = Number(result.invalidCount || 0) + Number(result.unknownCount || 0);
    $('#ageReportNote').classList.toggle('hidden', !omitted);
    $('#ageReportNote').textContent = omitted ? `Có ${num(omitted)} người chưa được phân nhóm do thiếu ngày sinh/ngày mất hoặc ngày tháng không hợp lệ.` : '';
  } catch (error) { setReportError(ids, error.message); }
}
