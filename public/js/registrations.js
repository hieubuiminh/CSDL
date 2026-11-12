import { $, $$, api, normalizeStatus, state, showNotice, statusClass, tableMarkup } from './shared.js';

export function syncRegistrationOfficer() {
  const select = $('#registrationForm [name=officerId]');
  const isStaff = state.user?.role === 'staff';
  if (isStaff) select.value = state.user.officerId || '';
  select.disabled = isStaff || !state.lookups.officers.length;
  const officer = state.lookups.officers.find(item => item.id === select.value);
  const preview = $('#officePreview');
  if (officer) {
    preview.textContent = `Đơn vị tiếp nhận: ${officer.officeName}`;
    preview.classList.remove('hidden');
  } else preview.classList.add('hidden');
}

export function initRegistrations(loadLookups, loadDashboard) {
  let searchTimer;
  $('#registrationSearch').addEventListener('input', () => { clearTimeout(searchTimer); searchTimer = setTimeout(loadRegistrations, 220); });
  $('#statusFilter').addEventListener('change', loadRegistrations);
  $('#registrationTable').addEventListener('change', async event => {
    const select = event.target.closest('[data-status-id]'); if (!select) return;
    try { await api(`/api/registrations/${encodeURIComponent(select.dataset.statusId)}/status`, { method: 'PATCH', body: JSON.stringify({ status: select.value }) }); select.className = `status-select ${statusClass(select.value)}`; showNotice('Đã cập nhật trạng thái hồ sơ.'); }
    catch (error) { showNotice(error.message, true); loadRegistrations(); }
  });
  $('#registrationTable').addEventListener('click', async event => {
    const button = event.target.closest('[data-delete-id]'); if (!button || state.user?.role !== 'admin') return;
    const id = button.dataset.deleteId;
    const name = button.dataset.deleteName;
    if (!window.confirm('Xóa hồ sơ ' + id + ' của ' + name + '? Thông tin an táng và giấy báo tử liên quan sẽ bị xóa. Không thể hoàn tác.')) return;
    button.disabled = true;
    try {
      await api('/api/registrations/' + encodeURIComponent(id), { method: 'DELETE' });
      showNotice('Đã xóa hồ sơ ' + id + '.');
      await loadRegistrations();
      loadDashboard().catch(error => showNotice(error.message, true));
    } catch (error) { showNotice(error.message, true); button.disabled = false; }
  });
  $('#exportRegistrations').addEventListener('click', () => {
    if (!state.user || $('#exportRegistrations').disabled) return;
    const columns = [['Số hồ sơ','id'],['Người đã mất','deceasedName'],['CCCD người mất','deceasedId'],['Người đăng ký','applicantName'],['Quan hệ','relation'],['Ngày đăng ký','registeredAt'],['Đơn vị tiếp nhận','officeName'],['Trạng thái','status']];
    const quote = value => `"${String(value ?? '').replaceAll('"', '""')}"`;
    const csv = '\ufeff' + [columns.map(([label]) => quote(label)).join(','), ...state.registrations.map(row => columns.map(([, key]) => quote(row[key])).join(','))].join('\r\n');
    const link = document.createElement('a'); const url = URL.createObjectURL(new Blob([csv], { type: 'text/csv;charset=utf-8' }));
    link.href = url; link.download = `ho-so-khai-tu-${new Date().toISOString().slice(0, 10)}.csv`; link.click(); URL.revokeObjectURL(url);
  });

  const dialog = $('#registrationDialog');
  const burialNames = ['burialId', 'burialForm', 'burialCemetery', 'burialDate'];
  function syncBurialFields() {
    const fields = burialNames.map(name => $(`#registrationForm [name=${name}]`));
    const hasBurial = fields.some(field => field.value.trim());
    fields.forEach(field => { field.required = hasBurial; });
  }
  burialNames.forEach(name => {
    const input = $(`#registrationForm [name=${name}]`);
    input.addEventListener('input', syncBurialFields); input.addEventListener('change', syncBurialFields);
  });
  function openRegistration() {
    $('#registrationError').textContent = ''; $('#registrationForm').reset();
    $('#officePreview').classList.add('hidden');
    syncRegistrationOfficer();
    $('#registrationForm [name=d_ethnicity]').value = 'Kinh'; $('#registrationForm [name=a_ethnicity]').value = 'Kinh';
    syncBurialFields();
    $('#registrationForm [name=registeredAt]').value = new Date().toISOString().slice(0, 10); dialog.showModal();
    $('.modal-body', dialog).scrollTop = 0;
  }
  $('#newRegistrationTop').addEventListener('click', openRegistration); $('#newRegistrationPage').addEventListener('click', openRegistration);
  $$('.close-dialog').forEach(button => button.addEventListener('click', () => dialog.close()));
  $('#registrationForm [name=officerId]').addEventListener('change', syncRegistrationOfficer);
  $('#registrationForm').addEventListener('submit', async event => {
    event.preventDefault(); const form = event.currentTarget; const values = new FormData(form); const value = key => String(values.get(key) || '').trim();
    const deathAt = value('deathAt').replace('T', ' ');
    const payload = {
      deceased: { cccd:value('d_cccd'), name:value('d_name'), birthDate:value('d_birthDate'), gender:value('d_gender'), hometown:value('d_hometown'), ethnicity:value('d_ethnicity'), phone:value('d_phone') },
      applicant: { cccd:value('a_cccd'), name:value('a_name'), birthDate:value('a_birthDate'), gender:value('a_gender'), hometown:value('a_hometown'), ethnicity:value('a_ethnicity'), phone:value('a_phone') },
      certificate: { id:value('certificateId'), issuedAt:value('issuedAt'), deathAt:deathAt.length === 16 ? `${deathAt}:00` : deathAt, placeDetail:value('placeDetail'), causeDescription:value('causeDescription'), causeId:value('causeId'), wardId:value('wardId'), hospitalId:value('hospitalId') },
      registration: { id:value('registrationId'), registeredAt:value('registeredAt'), relation:value('relation'), officerId:state.user?.role === 'staff' ? state.user.officerId : value('officerId'), status:value('status') || 'Chờ xử lý' },
      burial: burialNames.some(name => value(name)) ? { id:value('burialId'), form:value('burialForm'), cemetery:value('burialCemetery'), date:value('burialDate') } : null
    };
    const submit = event.submitter; submit.disabled = true; submit.textContent = 'Đang lưu…'; $('#registrationError').textContent = '';
    try { await api('/api/registrations', { method: 'POST', body: JSON.stringify(payload) }); dialog.close(); showNotice('Đã tạo hồ sơ khai tử.'); await loadLookups(); await loadDashboard(); if ($('#page-registrations').classList.contains('active-page')) loadRegistrations(); }
    catch (error) { $('#registrationError').textContent = error.message; }
    finally { submit.disabled = false; submit.textContent = 'Lưu hồ sơ'; }
  });

}

export async function loadRegistrations() {
  state.registrations = [];
  $('#exportRegistrations').disabled = true;
  $('#registrationTable').innerHTML = '<div class="loading-line">Đang tải hồ sơ…</div>';
  const query = new URLSearchParams({ search: $('#registrationSearch').value, status: $('#statusFilter').value });
  try { state.registrations = (await api(`/api/registrations?${query}`)).map(record => ({ ...record, status: normalizeStatus(record.status) })); $('#registrationTable').innerHTML = tableMarkup(state.registrations, false, state.user?.role === 'admin'); $('#exportRegistrations').disabled = false; }
  catch (error) { $('#registrationTable').replaceChildren(); showNotice(error.message, true); }
}
