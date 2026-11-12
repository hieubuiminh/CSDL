export const state = { user: null, lookups: { csyt: [], causes: [], wards: [], officers: [], offices: [] }, registrations: [] };
let sessionGeneration = 0;
const pendingRequests = new Set();

export function clearSessionData() {
  sessionGeneration++;
  for (const controller of pendingRequests) controller.abort();
  pendingRequests.clear();
  state.user = null;
  state.registrations = [];
  state.lookups = { csyt: [], causes: [], wards: [], officers: [], offices: [] };
  document.getElementById('appShell')?.classList.add('hidden');
  for (const dialog of document.querySelectorAll('dialog[open]')) dialog.close();
  for (const form of document.querySelectorAll('form')) form.reset();
  for (const input of document.querySelectorAll('#appShell input, #appShell textarea')) input.value = '';
  const searchStatus = document.getElementById('statusFilter');
  if (searchStatus) searchStatus.value = '';
  const reportYear = document.getElementById('reportYear');
  if (reportYear) reportYear.value = String(new Date().getFullYear());
  const resultIds = ['registrationTable', 'recentTable', 'lookupResult', 'yearChart', 'genderChart', 'genderReport', 'genderReportTable', 'areaReport', 'ageReportSummary', 'ageReport', 'hospitalReport', 'yearReport', 'yearReportTable', 'accountTable', 'settingsCards', 'inviteResult'];
  for (const id of resultIds) {
    const root = document.getElementById(id);
    if (root) root.replaceChildren();
  }
  const textIds = ['userName', 'userHandle', 'userInitial', 'userMenuName', 'userMenuHandle', 'userMenuInitial', 'userRole', 'userMenuRole', 'greetingName', 'officePreview', 'registrationError', 'areaReportScope', 'ageReportNote', 'hospitalReportPeriod', 'notice'];
  for (const id of textIds) {
    const node = document.getElementById(id);
    if (node) node.textContent = '';
  }
  for (const id of ['statTotal', 'statMonth', 'statActive', 'statDone']) {
    const node = document.getElementById(id);
    if (node) node.textContent = '—';
  }
  for (const select of document.querySelectorAll('select[data-options], #accountOfficerField select, #inviteOfficerId')) {
    select.replaceChildren(); select.disabled = true;
  }
  document.getElementById('notice')?.classList.add('hidden');
  const exportButton = document.getElementById('exportRegistrations');
  if (exportButton) exportButton.disabled = true;
}
export const $ = (selector, root = document) => root.querySelector(selector);
export const $$ = (selector, root = document) => [...root.querySelectorAll(selector)];
export const esc = value => String(value ?? '').replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
const iconNames = new Set(['layout-dashboard','file-text','search','chart-no-axes-column-increasing','settings-2','users-round','plus','calendar-days','refresh-cw','files','loader-circle','circle-check','arrow-right','download','key-round','log-out','x','building','user-round','hospital','map-pin','stethoscope','database','search-x','copy','shield','trash-2']);
export function icon(name, className = '') {
  if (!iconNames.has(name)) throw new RangeError(`Unknown interface icon: ${name}`);
  const extraClass = className ? ` ${esc(className)}` : '';
  return `<svg class="ui-icon${extraClass}" viewBox="0 0 24 24" aria-hidden="true" focusable="false"><use href="/assets/icons.svg#${name}"></use></svg>`;
}
export const fmt = value => value ? new Intl.DateTimeFormat('vi-VN', { day: '2-digit', month: '2-digit', year: 'numeric' }).format(new Date(`${String(value).slice(0, 10)}T00:00:00`)) : '—';
export const num = value => new Intl.NumberFormat('vi-VN').format(Number(value || 0));
export async function api(url, options = {}) {
  const generation = sessionGeneration;
  const controller = new AbortController();
  const abort = () => controller.abort();
  if (options.signal?.aborted) controller.abort();
  else options.signal?.addEventListener('abort', abort, { once:true });
  pendingRequests.add(controller);
  try {
    const response = await fetch(url, { credentials: 'same-origin', ...options, signal:controller.signal, cache:'no-store', headers: { ...(options.body ? { 'Content-Type': 'application/json' } : {}), ...(options.headers || {}) } });
    const data = await response.json().catch(() => ({}));
    if (generation !== sessionGeneration || controller.signal.aborted) {
      const error = new Error('Phiên làm việc đã thay đổi.'); error.name = 'AbortError'; throw error;
    }
    if (!response.ok) { const error = new Error(data.error || 'Không thể tải dữ liệu.'); error.status = response.status; throw error; }
    return data;
  } finally {
    pendingRequests.delete(controller);
    options.signal?.removeEventListener('abort', abort);
  }
}
export function showNotice(message, error = false) {
  const el = $('#notice'); el.textContent = message; el.classList.toggle('error', error); el.classList.remove('hidden');
  clearTimeout(showNotice.timer); showNotice.timer = setTimeout(() => el.classList.add('hidden'), 4500);
}
export const registrationStatuses = ['Đã duyệt', 'Chờ xử lý', 'Từ chối'];
export function normalizeStatus(status) {
  if (status === 'Đã hoàn tất') return 'Đã duyệt';
  if (['Đã tiếp nhận', 'Đang xử lý', 'Chờ duyệt'].includes(status)) return 'Chờ xử lý';
  return status;
}
export const statusClass = status => normalizeStatus(status) === 'Đã duyệt' ? 'done' : normalizeStatus(status) === 'Chờ xử lý' ? 'progress' : status === 'Từ chối' ? 'rejected' : 'received';
export function tableMarkup(rows, compact = false, canDelete = false) {
  if (!rows.length) return '<div class="empty-state"><span class="empty-state-icon">' + icon('database') + '</span><strong>Chưa có hồ sơ</strong></div>';
  const actionHead = canDelete ? '<th>THAO TÁC</th>' : '';
  const body = rows.map(r => {
    const normalizedStatus = normalizeStatus(r.status);
    const status = compact
      ? '<span class="status-pill ' + statusClass(normalizedStatus) + '">' + esc(normalizedStatus) + '</span>'
      : '<select class="status-select ' + statusClass(normalizedStatus) + '" data-status-id="' + esc(r.id) + '">' + registrationStatuses.map(s => '<option ' + (s === normalizedStatus ? 'selected' : '') + '>' + s + '</option>').join('') + '</select>';
    const action = canDelete
      ? '<td><button type="button" class="table-action" data-delete-id="' + esc(r.id) + '" data-delete-name="' + esc(r.deceasedName) + '" aria-label="Xóa hồ sơ ' + esc(r.id) + '">' + icon('trash-2') + ' Xóa</button></td>'
      : '';
    return '<tr><td><strong class="mono">' + esc(r.id) + '</strong></td><td><strong>' + esc(r.deceasedName) + '</strong><small>' + esc(r.deceasedId) + '</small></td><td><strong>' + esc(r.applicantName) + '</strong><small>' + esc(r.relation) + '</small></td><td>' + fmt(r.registeredAt) + '</td><td>' + esc(r.officeName || '—') + '</td><td>' + status + '</td>' + action + '</tr>';
  }).join('');
  return '<div class="table-wrap"><table><thead><tr><th>SỐ HỒ SƠ</th><th>NGƯỜI ĐÃ MẤT</th><th>NGƯỜI ĐĂNG KÝ</th><th>NGÀY ĐĂNG KÝ</th><th>ĐƠN VỊ TIẾP NHẬN</th><th>TRẠNG THÁI</th>' + actionHead + '</tr></thead><tbody>' + body + '</tbody></table></div>';
}
