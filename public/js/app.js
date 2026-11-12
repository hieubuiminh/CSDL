import { $, $$, api, clearSessionData, esc, showNotice, state } from './shared.js';
import { initAuth } from './auth.js';
import { loadDashboard } from './dashboard.js';
import { initReports, loadReport } from './reports/index.js';
import { initRegistrations, loadRegistrations, syncRegistrationOfficer } from './registrations.js';
import { initSettings, renderSettings, setLookupLoader } from './settings.js';
import { initLookup } from './lookup/index.js';
import { initAccounts, loadAccounts } from './accounts/index.js';

const pageNames = { dashboard:'Tổng quan', registrations:'Hồ sơ khai tử', lookup:'Tra cứu trích lục', 'report-gender':'Thống kê theo giới tính', 'report-areas':'Tử vong theo địa bàn', 'report-age-causes':'Nguyên nhân theo độ tuổi', 'report-hospitals':'Báo cáo cơ sở y tế', 'report-years':'Thống kê theo năm mất', settings:'Dữ liệu dùng chung', accounts:'Quản lý tài khoản' };
const adminPages = new Set(['settings', 'accounts']);
const recoveryDismissedKey = username => `khaiTuRecoverySetupDismissed:${username}`;
const hasDismissedRecoverySetup = username => { try { return localStorage.getItem(recoveryDismissedKey(username)) === 'true'; } catch { return false; } };
const rememberRecoverySetupDismissal = username => { try { localStorage.setItem(recoveryDismissedKey(username), 'true'); } catch { /* keep the dialog dismissible even when storage is disabled */ } };

async function loadLookups() {
  state.lookups = await api('/api/lookups');
  $$('select[data-options]').forEach(select => {
    const rows = state.lookups[select.dataset.options] || [];
    select.innerHTML = `<option value="">${rows.length ? 'Chọn thông tin' : 'Chưa có danh mục'}</option>` + rows.map(item => `<option value="${esc(item.id)}" ${item.officeName ? `data-office="${esc(item.officeName)}"` : ''}>${esc(item.name)}${item.officeName ? ` · ${esc(item.officeName)}` : ''}</option>`).join('');
    select.disabled = !rows.length;
  });
  syncRegistrationOfficer();
  renderSettings();
}

function enterApp(user) {
  const needsRecoverySetup = !user.recoveryConfigured;
  clearSessionData();
  closeUserMenu();
  state.user = user; $('#authScreen').classList.add('hidden'); $('#appShell').classList.remove('hidden');
  const isAdmin = user.role === 'admin';
  $('#adminNavSection').classList.toggle('hidden', !isAdmin);
  $('#navigation [data-page="settings"]').classList.toggle('hidden', !isAdmin);
  $('#navigation [data-page="accounts"]').classList.toggle('hidden', !isAdmin);
  $('#userAdminPanel').classList.toggle('hidden', !isAdmin);
  $('#userName').textContent = user.name || user.username; $('#greetingName').textContent = (user.name || 'cán bộ').split(' ').slice(-1)[0];
  $('#userHandle').textContent = `@${user.username}`; $('#userInitial').textContent = (user.name || 'C').trim().slice(0,1).toUpperCase();
  $('#userMenuName').textContent = user.name || user.username; $('#userMenuHandle').textContent = `@${user.username}`;
  $('#userMenuInitial').textContent = (user.name || 'C').trim().slice(0,1).toUpperCase();
  $('#userRole').textContent = isAdmin ? 'ADMIN' : 'Cán bộ';
  $('#userMenuRole').textContent = isAdmin ? 'ADMIN' : 'Cán bộ';
  $('#dashboardScopeLabel').textContent = isAdmin ? 'Toàn hệ thống' : 'Hồ sơ bạn tiếp nhận';
  $('#todayLabel').textContent = new Intl.DateTimeFormat('vi-VN', { weekday:'short', day:'2-digit', month:'long', year:'numeric' }).format(new Date());
  loadLookups().catch(error => showNotice(error.message, true)); navigate(location.hash.slice(1) || 'dashboard');
  if (needsRecoverySetup && !hasDismissedRecoverySetup(user.username)) $('#recoverySetupDialog').showModal();
}

function navigate(name) {
  if (!state.user) return;
  if (!Object.hasOwn(pageNames, name) || adminPages.has(name) && state.user.role !== 'admin') name = 'dashboard';
  if (location.hash.slice(1) !== name) history.replaceState(null, '', `#${name}`);
  $$('.page').forEach(page => page.classList.toggle('active-page', page.id === `page-${name}`));
  $$('.nav-item').forEach(button => {
    const isCurrentPage = button.dataset.page === name;
    button.classList.toggle('active', isCurrentPage);
    if (isCurrentPage) button.setAttribute('aria-current', 'page');
    else button.removeAttribute('aria-current');
  });
  $('#pageCrumb').textContent = pageNames[name] || pageNames.dashboard;
  document.title = `${pageNames[name]} · Quản lý khai tử`;
  if (name === 'dashboard') loadDashboard().catch(error => showNotice(error.message, true));
  if (name === 'registrations') loadRegistrations();
  if (name === 'accounts') loadAccounts();
  if (name === 'settings') renderSettings();
  loadReport(name);
}

function goToPage(name) { if (location.hash.slice(1) === name) navigate(name); else location.hash = name; }
window.addEventListener('hashchange', () => navigate(location.hash.slice(1)));
$('#navigation').addEventListener('click', event => { const button = event.target.closest('[data-page]'); if (button) goToPage(button.dataset.page); });
document.addEventListener('click', event => { const button = event.target.closest('[data-goto]'); if (button) goToPage(button.dataset.goto); });
$$('[data-refresh]').forEach(button => button.addEventListener('click', () => loadDashboard().then(() => showNotice('Đã cập nhật dữ liệu.')).catch(error => showNotice(error.message, true))));

$('#recoverySetupDialog').addEventListener('close', () => {
  if (state.user && !state.user.recoveryConfigured) rememberRecoverySetupDismissal(state.user.username);
});
function closeUserMenu() {
  $('#userMenu').classList.add('hidden');
  $('#userMenuToggle').setAttribute('aria-expanded', 'false');
  $('#userMenuToggle').setAttribute('aria-label', 'Mở menu tài khoản');
}
$('#userMenuToggle').addEventListener('click', () => {
  const opening = $('#userMenu').classList.contains('hidden');
  $('#userMenu').classList.toggle('hidden', !opening);
  $('#userMenuToggle').setAttribute('aria-expanded', String(opening));
  $('#userMenuToggle').setAttribute('aria-label', opening ? 'Đóng menu tài khoản' : 'Mở menu tài khoản');
  if (opening) $('#profileRecoveryBtn').focus();
});
document.addEventListener('click', event => { if (!event.target.closest('.user-row')) closeUserMenu(); });
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && !$('#userMenu').classList.contains('hidden')) {
    closeUserMenu(); $('#userMenuToggle').focus();
  }
});
$('#profileRecoveryBtn').addEventListener('click', () => {
  closeUserMenu(); $('#recoverySetupError').textContent = ''; $('#recoverySetupForm').reset(); $('#recoverySetupDialog').showModal();
});
$('#profilePasswordBtn').addEventListener('click', () => {
  closeUserMenu(); $('#changePasswordForm').reset(); $('#changePasswordError').textContent = ''; $('#changePasswordDialog').showModal();
});
$('#skipRecoverySetupBtn').addEventListener('click', () => $('#recoverySetupDialog').close());
$('#recoverySetupForm').addEventListener('submit', async event => {
  event.preventDefault(); const form = event.currentTarget; const button = form.querySelector('button[type="submit"]'); button.disabled = true;
  $('#recoverySetupError').textContent = '';
  try {
    const user = await api('/api/auth/recovery-setup', { method:'POST', body:JSON.stringify(Object.fromEntries(new FormData(form).entries())) });
    state.user = user.user; form.reset(); $('#recoverySetupDialog').close(); showNotice('Đã bật câu hỏi khôi phục cho tài khoản.');
  } catch (error) { $('#recoverySetupError').textContent = error.message; }
  finally { button.disabled = false; }
});

$$('.close-account-dialog').forEach(button => button.addEventListener('click', () => $('#changePasswordDialog').close()));
$('#changePasswordForm').addEventListener('submit', async event => {
  event.preventDefault();
  const form = event.currentTarget; const values = Object.fromEntries(new FormData(form).entries());
  const button = form.querySelector('button[type="submit"]');
  $('#changePasswordError').textContent = '';
  if (values.newPassword !== values.confirmPassword) { $('#changePasswordError').textContent = 'Hai mật khẩu mới chưa trùng khớp.'; return; }
  button.disabled = true;
  try {
    const result = await api('/api/auth/change-password', { method:'POST', body:JSON.stringify(values) });
    state.user = result.user; form.reset(); $('#changePasswordDialog').close(); showNotice('Đã đổi mật khẩu.');
  } catch (error) { $('#changePasswordError').textContent = error.message; }
  finally { button.disabled = false; }
});

setLookupLoader(loadLookups);
initReports(); initSettings(); initLookup(); initAccounts(); initRegistrations(loadLookups, loadDashboard); initAuth(enterApp);
