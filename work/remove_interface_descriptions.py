from pathlib import Path
import hashlib
import json
import re
import zipfile

root = Path(r'E:\CSDL\he_thong_quan_ly_dang_ky_khai_tu')
files = ['public/index.html', 'public/js/auth.js', 'public/js/shared.js', 'public/js/reports/areas/index.js', 'public/js/reports/hospitals/index.js', 'public/js/reports/age-causes/index.js']
database_before = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in (root / 'database').rglob('*') if p.is_file()}
with zipfile.ZipFile(root / 'work/before_remove_descriptions.zip', 'w', zipfile.ZIP_DEFLATED) as backup:
    for relative in files:
        backup.write(root / relative, relative)

page = root / 'public/index.html'
html = page.read_text(encoding='utf-8')
html, removed = re.subn(r'<p\b(?![^>]*\bid\s*=)[^>]*>.*?</p>', '', html, flags=re.S)
html = re.sub(r'<p\b[^>]*\bid="authHint"[^>]*>.*?</p>', '', html, flags=re.S)
for text in ['Hồ sơ trong hệ thống', 'Hồ sơ đăng ký trong tháng', 'Chưa hoàn tất hoặc từ chối', 'Hồ sơ đã xử lý xong']:
    html = html.replace(f'<small>{text}</small>', '')
for text in ['Câu trả lời được lưu dạng mã băm.', 'Phiên đăng nhập hiện tại sẽ tiếp tục.']:
    html = html.replace(f'<span>{text}</span>', '')
html = html.replace('<small class="field-hint">UBND tiếp nhận được xác định từ đơn vị công tác của cán bộ.</small>', '')
page.write_text(html, encoding='utf-8')

auth = root / 'public/js/auth.js'
content, auth_removed = re.subn(r"\s*\$\('#authHint'\)\.textContent = [^;\n]*;", '', auth.read_text(encoding='utf-8'))
assert auth_removed == 4
auth.write_text(content, encoding='utf-8')

shared = root / 'public/js/shared.js'
content = shared.read_text(encoding='utf-8').replace('<p>Hồ sơ sẽ xuất hiện ở đây sau khi được tạo.</p>', '')
shared.write_text(content, encoding='utf-8')

hospital = root / 'public/js/reports/hospitals/index.js'
content = hospital.read_text(encoding='utf-8').replace('<p>Trong quý được báo cáo, chưa có cơ sở y tế cấp trên 50 giấy báo tử.</p>', '')
hospital.write_text(content, encoding='utf-8')

age = root / 'public/js/reports/age-causes/index.js'
content = age.read_text(encoding='utf-8')
content = content.replace("${row.commonCauses.length > 1 ? '<p class=\"field-hint\">Các nguyên nhân đồng hạng.</p>' : ''}", '')
age.write_text(content, encoding='utf-8')

database_after = {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in (root / 'database').rglob('*') if p.is_file()}
assert database_before == database_after
print(json.dumps({'removedStaticParagraphs': removed, 'removedAuthDescriptions': auth_removed, 'databaseUnchanged': True}))
