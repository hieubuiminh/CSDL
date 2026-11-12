import { $, api, fmt, num } from '../../shared.js';
import { reportTable, renderBars, setLoading, setReportError } from '../shared.js';

export async function loadHospitalReport() {
  setLoading(['hospitalReport']);
  try {
    const result = await api('/api/reports/hospitals');
    const period = result.period;
    const inclusiveEnd = new Date(`${String(period.end).slice(0, 10)}T00:00:00Z`);
    inclusiveEnd.setUTCDate(inclusiveEnd.getUTCDate() - 1);
    $('#hospitalReportPeriod').textContent = `${period.label} · Từ ${fmt(period.start)} đến ${fmt(inclusiveEnd.toISOString().slice(0, 10))} · Theo ngày cấp giấy báo tử`;
    const rows = [...result.rows].sort((a, b) => Number(b.value) - Number(a.value) || a.name.localeCompare(b.name, 'vi'));
    $('#hospitalReport').innerHTML = rows.length
      ? `${renderBars(rows, 'giấy báo tử')}${reportTable(['Mã CSYT', 'Cơ sở y tế', 'Số giấy báo tử đã cấp', 'Số ca mất tại CSYT (ước tính)', 'Tỷ lệ tại CSYT (ước tính)'], rows.map(row => [row.id, row.name, num(row.value), num(row.estimatedDeaths), `${Number(row.estimatedPercent || 0).toLocaleString('vi-VN',{minimumFractionDigits:2,maximumFractionDigits:2})}%`]))}`
      : '<div class="empty-state slim"><strong>Chưa có cơ sở nào vượt ngưỡng</strong></div>';
  } catch (error) { setReportError(['hospitalReport'], error.message); }
}
