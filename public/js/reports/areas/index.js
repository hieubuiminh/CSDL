import { $, api, num } from '../../shared.js';
import { reportTable, setLoading, setReportError } from '../shared.js';

export function initAreaReport() {
  const input = $('#reportYear'); input.value = String(new Date().getFullYear());
  input.addEventListener('input', () => input.setCustomValidity(''));
  $('#reportYearForm').addEventListener('submit', event => { event.preventDefault(); loadAreaReport(); });
}

export async function loadAreaReport() {
  const input = $('#reportYear'); const year = Number(input.value.trim());
  if (!Number.isInteger(year) || year < 1000 || year > 9998) {
    input.setCustomValidity('Vui lòng nhập năm từ 1000 đến 9998.'); input.reportValidity(); return;
  }
  input.setCustomValidity(''); setLoading(['areaReport']);
  try {
    const result = await api(`/api/reports/areas?year=${encodeURIComponent(year)}`);
    // The selected year can change while an earlier request is in flight.
    if (Number(input.value) !== year) return;
    const rows = [...result.rows].sort((a, b) => Number(b.value) - Number(a.value) || a.name.localeCompare(b.name, 'vi'));
    const total = rows.reduce((sum, row) => sum + Number(row.value || 0), 0);
    $('#areaReportCaption').textContent = `Xã/phường Hà Nội · Năm đăng ký ${result.year}`;
    $('#areaReportScope').textContent = `${num(rows.length)} xã/phường · ${num(total)} ca`;
    $('#areaReport').innerHTML = reportTable(['Xếp hạng', 'Mã xã/phường', 'Xã/phường', 'Số ca đăng ký'], rows.map((row, index) => [num(index + 1), row.id, row.name, num(row.value)]), 'Chưa có xã/phường trong danh mục.');
  } catch (error) { setReportError(['areaReport'], error.message); }
}
