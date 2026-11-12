import { $, api, esc, fmt, icon, normalizeStatus, statusClass } from '../shared.js';

function localDateTime(value) {
  if (!value) return '—';
  const text = String(value).replace('T', ' ');
  const match = /^(\d{4}-\d{2}-\d{2})[ ](\d{2}:\d{2})(?::(\d{2}))?/.exec(text);
  return match ? `${fmt(match[1])} ${match[2]}${match[3] ? `:${match[3]}` : ''}` : '—';
}

export function initLookup() {
  $('#lookupForm').addEventListener('submit', async event => {
    event.preventDefault();
    const cccd = $('#lookupCccd').value.trim(); const root = $('#lookupResult');
    const button = event.currentTarget.querySelector('button');
    if (!/^[0-9]{12}$/.test(cccd)) { $('#lookupCccd').setCustomValidity('CCCD gồm đúng 12 chữ số.'); $('#lookupCccd').reportValidity(); return; }
    root.innerHTML = '<div class="loading-line" role="status">Đang tra cứu…</div>'; button.disabled = true;
    try {
      const record = await api(`/api/registrations/${encodeURIComponent(cccd)}`);
      record.status = normalizeStatus(record.status);
      const details = [['Họ tên người đã mất', record.deceasedName], ['CCCD người đã mất', record.deceasedId], ['Ngày sinh', fmt(record.birthDate)], ['Ngày giờ mất', localDateTime(record.deathAt)], ['Nguyên nhân tử vong', record.cause], ['Chi tiết nguyên nhân', record.causeDescription], ['Người đi khai tử', record.applicantName], ['Quan hệ với người mất', record.relation], ['UBND cấp khai tử', record.officeName], ['Cán bộ tiếp nhận', record.officerName], ['Cơ sở y tế cấp giấy', record.hospitalName], ['Số giấy báo tử', record.certificateId], ['Ngày đăng ký', fmt(record.registeredAt)]];
      root.innerHTML = `<article class="panel result-card"><div class="panel-heading"><div><div class="eyebrow">TRÍCH LỤC HỒ SƠ</div><h2>${esc(record.deceasedName)}</h2><p>Số hồ sơ ${esc(record.id)}</p></div><div class="heading-actions"><span class="status-pill ${statusClass(record.status)}">${esc(record.status)}</span><button type="button" class="button secondary" id="printExtract">In trích lục</button></div></div><div class="detail-grid">${details.map(([label, value]) => `<div><small>${esc(label)}</small><strong>${esc(value || '—')}</strong></div>`).join('')}</div></article>`;
      $('#printExtract').addEventListener('click', () => window.print());
    } catch (error) {
      root.innerHTML = `<div class="empty-state" role="status"><span class="empty-state-icon">${icon('search-x')}</span><strong>${error.status === 404 ? 'Không tìm thấy hồ sơ' : 'Chưa thể tra cứu'}</strong><p>${esc(error.message)}</p></div>`;
    } finally { button.disabled = false; }
  });
  $('#lookupCccd').addEventListener('input', event => event.currentTarget.setCustomValidity(''));
}
