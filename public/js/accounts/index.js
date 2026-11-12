import { $, api, esc, fmt, icon, showNotice, state } from '../shared.js';

let accountUsers = [];
let accountOfficers = [];

function officerOptions(selectedId = '', userId = '') {
  const available = accountOfficers.filter(officer => !accountUsers.some(user =>
    user.officerId === officer.id && String(user.id) !== String(userId)));
  const placeholder = available.length ? 'Chọn cán bộ' : 'Không còn cán bộ chưa liên kết';
  return `<option value="">${placeholder}</option>` + available.map(officer =>
    `<option value="${esc(officer.id)}"${officer.id === selectedId ? ' selected' : ''}>${esc(officer.id)} · ${esc(officer.name)}${officer.officeName ? ` · ${esc(officer.officeName)}` : ''}</option>`).join('');
}

function syncAccountRoleFields() {
  const isStaff = $('#userAdminForm [name=role]').value === 'staff';
  const select = $('#userAdminForm [name=officerId]');
  $('#accountOfficerField').classList.toggle('hidden', !isStaff);
  select.required = isStaff;
  select.disabled = !isStaff;
  if (!isStaff) select.value = '';
}

function refreshOfficerFields() {
  for (const select of [$('#userAdminForm [name=officerId]'), $('#inviteOfficerId')]) {
    const previous = select.value;
    select.innerHTML = officerOptions(previous);
    select.disabled = false;
  }
  syncAccountRoleFields();
}

function syncAccountRow(row) {
  const role = $('[data-user-role]', row);
  const officer = $('[data-user-officer]', row);
  const isOwn = row.dataset.userId === String(state.user.id);
  if (role.value === 'admin') officer.value = '';
  officer.disabled = isOwn || role.value !== 'staff';
  const changed = role.value !== row.dataset.savedRole || officer.value !== row.dataset.savedOfficer;
  $('[data-save-account]', row).disabled = isOwn || !changed;
}

export async function loadAccounts() {
  if (state.user?.role !== 'admin') return;
  const root = $('#accountTable'); root.innerHTML = '<div class="loading-line">Đang tải danh sách tài khoản…</div>';
  try {
    const [users, lookups] = await Promise.all([api('/api/users'), api('/api/lookups')]);
    accountUsers = users;
    accountOfficers = lookups.officers;
    refreshOfficerFields();
    root.innerHTML = users.length ? `<div class="table-wrap account-table"><table><thead><tr><th>Họ tên</th><th>Tên đăng nhập</th><th>Ngày tạo</th><th>Vai trò</th><th>Cán bộ tiếp nhận liên kết</th><th>Thao tác</th></tr></thead><tbody>${users.map(user => {
      const ownAccount = String(user.id) === String(state.user.id);
      return `<tr data-user-id="${esc(user.id)}" data-saved-role="${esc(user.role)}" data-saved-officer="${esc(user.officerId || '')}"><td><strong>${esc(user.name)}</strong></td><td>${esc(user.username)}${ownAccount ? ' <small>(Bạn)</small>' : ''}</td><td>${fmt(user.createdAt)}</td><td><select class="role-select" aria-label="Vai trò của ${esc(user.username)}" data-user-role${ownAccount ? ' disabled title="Không thể tự đổi vai trò của mình"' : ''}><option value="staff"${user.role === 'staff' ? ' selected' : ''}>Cán bộ</option><option value="admin"${user.role === 'admin' ? ' selected' : ''}>ADMIN</option></select></td><td><select class="officer-select" aria-label="Cán bộ liên kết với ${esc(user.username)}" data-user-officer${user.role !== 'staff' || ownAccount ? ' disabled' : ''}>${officerOptions(user.officerId || '', user.id)}</select></td><td><button type="button" class="button secondary" data-save-account disabled aria-label="Lưu quyền của ${esc(user.username)}">Lưu</button></td></tr>`;
    }).join('')}</tbody></table></div>` : '<div class="empty-inline">Chưa có tài khoản.</div>';
  } catch (error) { root.innerHTML = `<div class="empty-inline" role="alert">${esc(error.message)}</div>`; }
}

export function initAccounts() {
  $('#reloadAccounts').addEventListener('click', loadAccounts);
  $('#userAdminForm [name=role]').addEventListener('change', syncAccountRoleFields);
  $('#userAdminForm [name=officerId]').addEventListener('change', event => {
    const name = $('#userAdminForm [name=displayName]');
    if (!name.value.trim()) name.value = accountOfficers.find(officer => officer.id === event.target.value)?.name || '';
  });
  $('#userAdminForm').addEventListener('submit', async event => {
    event.preventDefault(); if (state.user?.role !== 'admin') return;
    const form = event.currentTarget; const button = form.querySelector('button'); button.disabled = true;
    const body = Object.fromEntries(new FormData(form).entries());
    if (body.role === 'admin') body.officerId = null;
    try {
      await api('/api/users', { method:'POST', body:JSON.stringify(body) });
      form.reset(); syncAccountRoleFields(); showNotice('Đã tạo tài khoản.'); await loadAccounts();
    } catch (error) { showNotice(error.message, true); } finally { button.disabled = false; }
  });
  $('#accountTable').addEventListener('change', event => {
    const select = event.target.closest('[data-user-role], [data-user-officer]');
    if (select && state.user?.role === 'admin') syncAccountRow(select.closest('[data-user-id]'));
  });
  $('#accountTable').addEventListener('click', async event => {
    const button = event.target.closest('[data-save-account]');
    if (!button || state.user?.role !== 'admin') return;
    const row = button.closest('[data-user-id]');
    const roleSelect = $('[data-user-role]', row); const officerSelect = $('[data-user-officer]', row);
    const role = roleSelect.value;
    if (role === 'staff' && !officerSelect.value) {
      showNotice('Hãy chọn cán bộ tiếp nhận liên kết với tài khoản.', true); officerSelect.focus(); return;
    }
    button.disabled = true; roleSelect.disabled = true; officerSelect.disabled = true;
    try {
      await api(`/api/users/${encodeURIComponent(row.dataset.userId)}/role`, { method:'PATCH', body:JSON.stringify({ role, officerId:role === 'staff' ? officerSelect.value : null }) });
      showNotice('Đã cập nhật quyền và cán bộ liên kết.'); await loadAccounts();
    } catch (error) {
      roleSelect.disabled = false; syncAccountRow(row); showNotice(error.message, true);
    }
  });
  $('#createInviteBtn').addEventListener('click', async event => {
    if (state.user?.role !== 'admin') return;
    const officerSelect = $('#inviteOfficerId');
    if (!officerSelect.reportValidity()) return;
    const officerId = officerSelect.value;
    const button = event.currentTarget; button.disabled = true;
    try {
      const invite = await api('/api/invitations', { method:'POST', body:JSON.stringify({ officerId }) });
      const officer = accountOfficers.find(item => item.id === officerId);
      const result = $('#inviteResult');
      result.innerHTML = `<strong>Mã mời ${esc(officerId)}${officer ? ` · ${esc(officer.name)}` : ''}: <code>${esc(invite.code)}</code></strong><span>Có hiệu lực đến ${esc(new Intl.DateTimeFormat('vi-VN', { dateStyle:'short', timeStyle:'short' }).format(new Date(invite.expiresAt)))}. Dùng một lần.</span><button type="button" class="button secondary" id="copyInviteBtn">${icon('copy')} Sao chép mã</button>`;
      result.classList.remove('hidden'); $('#copyInviteBtn').addEventListener('click', async () => {
        try { await navigator.clipboard.writeText(invite.code); showNotice('Đã sao chép mã mời.'); } catch { showNotice('Không thể tự sao chép. Hãy chọn mã mời để sao chép thủ công.'); }
      });
    } catch (error) { showNotice(error.message, true); } finally { button.disabled = false; }
  });
  syncAccountRoleFields();
}
