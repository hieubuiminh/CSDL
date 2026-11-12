import { $, api, icon, num, showNotice, state } from './shared.js';

const settingTypes = [
  { key:'office', title:'Cơ quan tiếp nhận', icon:'building', fields:[['id','Mã UBND'],['name','Tên UBND'],['level','Cấp hành chính'],['address','Địa chỉ'],['phone','Số điện thoại']] },
  { key:'officer', title:'Cán bộ tiếp nhận', icon:'user-round', fields:[['id','Mã cán bộ'],['identity','CCCD cán bộ'],['name','Họ và tên'],['role','Chức vụ'],['phone','Số điện thoại'],['officeId','Mã UBND công tác']] },
  { key:'hospital', title:'Cơ sở y tế', icon:'hospital', fields:[['id','Mã cơ sở'],['name','Tên cơ sở y tế'],['address','Địa chỉ'],['phone','Số điện thoại']] },
  { key:'ward', title:'Xã / phường nơi mất', icon:'map-pin', fields:[['id','Mã xã/phường'],['name','Tên xã/phường']] },
  { key:'cause', title:'Nguyên nhân tử vong', icon:'stethoscope', fields:[['id','Mã nguyên nhân'],['name','Tên nhóm nguyên nhân']] }
];

function masterField(type, key, label) {
  if (key === 'level') return `<label>${label}<select name="level" required><option value="">Chọn cấp hành chính</option><option>Xã</option><option>Phường</option></select></label>`;
  if (key === 'unitType') return `<label>${label}<select name="unitType" required><option value="">Chọn loại đơn vị</option><option>Xã</option><option>Phường</option><option>Đặc khu</option></select></label>`;
  const length = key === 'id' || key === 'officeId' ? 20 : key === 'identity' ? 12 : key === 'phone' ? 15 : key === 'address' ? 255 : key === 'level' ? 50 : key === 'role' || key === 'province' ? 100 : key === 'name' && ['officer', 'ward'].includes(type.key) ? 100 : 150;
  const placeholder = key === 'officeId' ? ' placeholder="Mã UBND đã tạo"' : key === 'province' ? ' placeholder="Ví dụ: Hà Nội"' : '';
  const identity = key === 'identity' ? ' minlength="12" pattern="[0-9]{12}" inputmode="numeric" title="CCCD gồm đúng 12 chữ số"' : '';
  return `<label>${label}<input name="${key}" maxlength="${length}"${placeholder}${identity}${key === 'phone' ? ' type="tel" required' : ' required'}></label>`;
}

export function renderSettings() {
  const counts = { office:state.lookups.offices.length, officer:state.lookups.officers.length, hospital:state.lookups.csyt.length, ward:state.lookups.wards.length, cause:state.lookups.causes.length };
  $('#settingsCards').innerHTML = settingTypes.map(type => `<article class="panel setting-card"><div class="setting-head"><div class="setting-symbol">${icon(type.icon)}</div><div><h2>${type.title}</h2><small>${num(counts[type.key])} mục đã có</small></div></div><form class="master-form" data-master="${type.key}">${type.fields.map(([key,label]) => masterField(type, key, label)).join('')}<button class="button secondary full">${icon('plus')} Thêm danh mục</button></form></article>`).join('');

}

export function initSettings() {
  $('#settingsCards').addEventListener('submit', async event => {
    const form = event.target.closest('[data-master]'); if (!form) return; event.preventDefault(); const button = form.querySelector('button'); button.disabled = true;
    try { const result = await api(`/api/master/${form.dataset.master}`, { method:'POST', body:JSON.stringify(Object.fromEntries(new FormData(form).entries())) }); showNotice(result.warning || 'Đã thêm danh mục.', Boolean(result.warning)); await loadLookups(); }
    catch (error) { showNotice(error.message, true); } finally { button.disabled = false; }
  });

}

let loadLookups;
export function setLookupLoader(loader) { loadLookups = loader; }
