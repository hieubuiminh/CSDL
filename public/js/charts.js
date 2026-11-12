import { esc, num } from './shared.js';

// A restrained indigo, coral, and slate palette keeps chart categories distinct.
export const chartPalette = ['#625ed1', '#e28b70', '#6488b4', '#4f9b91', '#c19a4f', '#9580b7', '#849c6d', '#c27683'];

export function renderYearChart(rows, { className = '' } = {}) {
  if (!rows.length) return `<div class="year-chart ${className}"><div class="empty-inline">Chưa có dữ liệu theo năm.</div></div>`;

  const values = rows.map(row => Math.max(0, Number(row.value) || 0));
  const max = Math.max(1, ...values);
  const minYear = Math.min(...rows.map(row => Number(row.year)).filter(Number.isFinite));
  const maxYear = Math.max(...rows.map(row => Number(row.year)).filter(Number.isFinite));
  const width = className.includes('report') ? 560 : 760;
  const top = 26, bottom = 174, left = 58, right = width - 18;
  const yearSpan = maxYear - minYear;
  const points = rows.map((row, index) => {
    const year = Number(row.year);
    const xRatio = yearSpan > 0 && Number.isFinite(year) ? (year - minYear) / yearSpan : (rows.length === 1 ? .5 : index / (rows.length - 1));
    return { row, value: values[index], x: left + xRatio * (right - left), y: bottom - values[index] / max * (bottom - top) };
  });

  if (rows.length < 3) {
    const columns = points.map(({ row, value }) => {
      const height = value ? Math.max(3, value / max * 100) : 0;
      return `<div class="bar-column${value === max ? ' is-peak' : ''}" role="listitem" aria-label="Năm ${esc(row.year)}: ${num(value)} người" title="${esc(row.year)} · ${num(value)} người"><span>${num(value)}</span><div class="bar-track" aria-hidden="true"><i style="height:${height}%"></i></div><small>${esc(row.year)}</small></div>`;
    }).join('');
    return `<div class="year-chart ${className}"><div class="bar-chart"><div class="bar-plot" style="--chart-min-width:${rows.length * 46}px" role="list" aria-label="Số người đã mất theo năm mất">${columns}</div></div></div>`;
  }

  const linePath = points.map((point, index) => `${index ? 'L' : 'M'} ${point.x.toFixed(1)} ${point.y.toFixed(1)}`).join(' ');
  const areaPath = `${linePath} L ${right} ${bottom} L ${left} ${bottom} Z`;
  const trendColor = className.includes('report') ? chartPalette[2] : chartPalette[0];
  const axis = [top, (top + bottom) / 2, bottom].map(y => `<line x1="${left}" y1="${y}" x2="${right}" y2="${y}"/>`).join('');
  const yearLabels = points.map(({ row, x }, index) => {
    const step = Math.ceil(points.length / 8);
    if (index !== points.length - 1 && index % step !== 0) return '';
    return `<text class="trend-year" x="${x.toFixed(1)}" y="211" text-anchor="middle">${esc(row.year)}</text>`;
  }).join('');
  const peakIndex = values.indexOf(max);
  const valueLabels = points.map(({ value, x, y }, index) => {
    if (points.length > 6 && index !== points.length - 1 && index !== peakIndex) return '';
    return `<text class="trend-value" x="${x.toFixed(1)}" y="${Math.max(15, y - 12).toFixed(1)}" text-anchor="middle">${num(value)}</text>`;
  }).join('');
  const markers = points.map(({ row, value, x, y }, index) => `<circle class="trend-dot${index === points.length - 1 ? ' is-latest' : ''}" cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="${index === points.length - 1 ? 5 : 4}"><title>${esc(row.year)}: ${num(value)} người</title></circle>`).join('');
  const label = rows.map((row, index) => `${row.year}: ${num(values[index])}`).join(', ');
  return `<div class="year-chart ${className}"><svg class="year-trend-svg" viewBox="0 0 ${width} 226" role="img" aria-label="${esc(`Số người đã mất theo năm mất. ${label}`)}">
    <defs><linearGradient id="year-area-fill-${className || 'dashboard'}" x1="0" y1="0" x2="0" y2="1"><stop offset="0%" stop-color="${trendColor}" stop-opacity=".28"/><stop offset="100%" stop-color="${trendColor}" stop-opacity=".015"/></linearGradient></defs>
    <g class="trend-grid" aria-hidden="true">${axis}<text x="49" y="${top + 4}" text-anchor="end">${num(max)}</text><text x="49" y="${bottom + 4}" text-anchor="end">0</text></g>
    <path class="trend-area" d="${areaPath}" fill="url(#year-area-fill-${className || 'dashboard'})"/>
    <path class="trend-line" d="${linePath}"/>
    ${markers}${valueLabels}${yearLabels}
  </svg></div>`;
}

export function renderDonutChart(rows, { unit = 'người' } = {}) {
  if (!rows.length) return '<div class="empty-inline">Chưa có dữ liệu.</div>';

  const values = rows.map(row => Math.max(0, Number(row.value) || 0));
  const total = values.reduce((sum, value) => sum + value, 0);
  let angle = 0;
  const stops = total ? rows.map((_, index) => {
    const start = angle;
    angle += values[index] * 100 / total;
    return `${chartPalette[index % chartPalette.length]} ${start}% ${angle}%`;
  }).join(', ') : '#e6ece5 0% 100%';
  const label = rows.map((row, index) => `${row.name}: ${num(values[index])}`).join(', ');
  const legend = rows.map((row, index) => `<div><span class="legend-dot" style="--legend-color:${chartPalette[index % chartPalette.length]}"></span><span>${esc(row.name)}</span><strong>${num(values[index])}</strong><small>${total ? Math.round(values[index] * 100 / total) : 0}%</small></div>`).join('');

  return `<div class="gender-visual-row"><div class="gender-donut" style="--gender-stops:${stops}" role="img" aria-label="${esc(label)}"><div class="gender-donut-center"><strong>${num(total)}</strong><small>${esc(unit)}</small></div></div><div class="gender-legend">${legend}</div></div>`;
}
