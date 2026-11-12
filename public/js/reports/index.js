import { initAreaReport, loadAreaReport } from './areas/index.js';
import { loadGenderReport } from './gender/index.js';
import { loadAgeCauseReport } from './age-causes/index.js';
import { loadHospitalReport } from './hospitals/index.js';
import { loadYearReport } from './years/index.js';

const reportLoaders = {
  'report-gender': loadGenderReport,
  'report-areas': loadAreaReport,
  'report-age-causes': loadAgeCauseReport,
  'report-hospitals': loadHospitalReport,
  'report-years': loadYearReport
};

export function initReports() {
  initAreaReport();
  document.querySelectorAll('[data-reload-report]').forEach(button => button.addEventListener('click', () => loadReport(button.closest('.page').id.slice(5))));
}

export function loadReport(name) { return reportLoaders[name]?.(); }
