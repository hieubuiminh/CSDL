import { esc, num } from '../shared.js';

export function reportTable(columns, rows, empty = 'Chưa có dữ liệu.') {
  if (!rows.length) return `<div class="empty-inline">${esc(empty)}</div>`;
  return `<div class="table-wrap report-data-table"><table><thead><tr>${columns.map(column => `<th scope="col">${esc(column)}</th>`).join('')}</tr></thead><tbody>${rows.map(row => `<tr>${row.map(cell => `<td>${esc(cell)}</td>`).join('')}</tr>`).join('')}</tbody></table></div>`;
}

export function renderBars(rows, unit = 'người') {
  if (!rows.length) return '<div class="empty-inline">Chưa có dữ liệu.</div>';
  const max = Math.max(1, ...rows.map(row => Number(row.value) || 0));
  return `<div class="report-bar-list" role="list">${rows.map(row => `<div class="report-bar-row" role="listitem"><div class="report-bar-meta"><span class="report-bar-label">${esc(row.name)}</span><span class="report-bar-numbers"><strong>${num(row.value)} <small>${esc(unit)}</small></strong></span></div><div class="report-bar-track" aria-hidden="true"><i style="width:${Math.max(0, Number(row.value) || 0) / max * 100}%"></i></div></div>`).join('')}</div>`;
}

export function setLoading(ids) {
  ids.forEach(id => { document.getElementById(id).innerHTML = '<div class="loading-line" role="status">Đang tải số liệu…</div>'; });
}

export function setReportError(ids, message) {
  ids.forEach(id => { document.getElementById(id).innerHTML = `<div class="empty-inline report-load-error" role="alert">${esc(message)}</div>`; });
}
