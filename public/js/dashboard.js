import { $, api, num, tableMarkup } from './shared.js';
import { renderDonutChart, renderYearChart } from './charts.js';

export async function loadDashboard() {
  const data = await api('/api/dashboard');
  $('#statTotal').textContent = num(data.cards.total); $('#statMonth').textContent = num(data.cards.thisMonth);
  $('#statActive').textContent = num(data.cards.active); $('#statDone').textContent = num(data.cards.completed);
  $('#yearChart').innerHTML = renderYearChart(data.yearly);
  $('#genderChart').innerHTML = renderDonutChart(data.gender);
  $('#recentTable').innerHTML = tableMarkup(data.recent, true);
}
