import { $, api, num } from '../../shared.js';
import { renderYearChart } from '../../charts.js';
import { reportTable, setLoading, setReportError } from '../shared.js';

export async function loadYearReport() {
  const ids = ['yearReport', 'yearReportTable']; setLoading(ids);
  try {
    const rows = (await api('/api/reports/years')).sort((a, b) => Number(a.year) - Number(b.year));
    $('#yearReport').innerHTML = renderYearChart(rows, { className: 'report-year-chart' });
    $('#yearReportTable').innerHTML = reportTable(['Năm mất', 'Số người đã mất'], rows.map(row => [row.year, num(row.value)]));
  } catch (error) { setReportError(ids, error.message); }
}
