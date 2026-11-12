import { $, api, num } from '../../shared.js';
import { renderDonutChart } from '../../charts.js';
import { reportTable, setLoading, setReportError } from '../shared.js';

export async function loadGenderReport() {
  const ids = ['genderReport', 'genderReportTable']; setLoading(ids);
  try {
    const rows = await api('/api/reports/gender');
    const total = rows.reduce((sum, row) => sum + Number(row.value || 0), 0);
    $('#genderReport').innerHTML = renderDonutChart(rows);
    $('#genderReportTable').innerHTML = reportTable(['Giới tính', 'Số người đã mất', 'Tỷ lệ'], rows.map(row => [row.name, num(row.value), `${total ? (Number(row.value || 0) / total * 100).toLocaleString('vi-VN', { maximumFractionDigits: 1 }) : 0}%`]).concat(total ? [['Tổng cộng', num(total), '100%']] : []));
  } catch (error) { setReportError(ids, error.message); }
}
