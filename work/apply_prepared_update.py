from pathlib import Path
from datetime import datetime
import hashlib
import json
import shutil
import zipfile

target_root = Path(r'E:\CSDL\he_thong_quan_ly_dang_ky_khai_tu')
staged_root = Path(r'C:\Users\ADMIN\Documents\Codex\2026-11-09\b-n-i-b-n-v-6\work\he_thong_quan_ly_dang_ky_khai_tu')
original_backup = Path(r'C:\Users\ADMIN\Documents\Codex\2026-11-09\b-n-i-b-n-v-6\outputs\ma_nguon_truoc_cap_nhat.zip')

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def database_snapshot():
    return {str(path.relative_to(target_root)): digest(path) for path in (target_root / 'database').rglob('*') if path.is_file()}

before_database = database_snapshot()
expected_sql_hash = '3268c260c20ee9668d92624c936cec52036cf6c727b75c4257a755800ba5841c'
assert digest(target_root / 'database' / 'he_thong_quan_ly_dang_ky_khai_tu.sql') == expected_sql_hash, 'SQL goc da thay doi; dung de kiem tra.'
with zipfile.ZipFile(original_backup) as original:
    for entry in original.infolist():
        if not entry.is_dir():
            current = target_root / entry.filename
            assert current.is_file() and current.read_bytes() == original.read(entry), f'Ma nguon goc da thay doi: {entry.filename}'

staged_files = []
for directory in ('backend', 'public', 'docs', 'tests'):
    staged_files.extend(path for path in (staged_root / directory).rglob('*') if path.is_file())
staged_files.extend(staged_root / name for name in ('package.json', 'README.md', '.dockerignore', 'docker/Dockerfile', 'docker/compose.yaml'))
changes = []
for source in sorted(staged_files):
    relative = source.relative_to(staged_root)
    destination = (target_root / relative).resolve()
    assert target_root.resolve() in destination.parents and relative.parts[0] != 'database' and source.suffix.lower() != '.sql'
    if not destination.is_file() or digest(source) != digest(destination):
        changes.append((source, destination, relative))

backup_path = target_root / 'work' / ('ma_nguon_truoc_cap_nhat_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.zip')
with zipfile.ZipFile(backup_path, 'w', zipfile.ZIP_DEFLATED) as backup:
    for _, destination, relative in changes:
        if destination.is_file():
            backup.write(destination, relative)

for source, destination, relative in changes:
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, destination)
    assert digest(source) == digest(destination), f'Sao chep khong dat: {relative}'

after_database = database_snapshot()
assert before_database == after_database, 'CSDL phai duoc giu nguyen.'
report = {'applied': True, 'target': str(target_root), 'changedFiles': [str(relative) for _, _, relative in changes], 'backup': str(backup_path), 'databaseUnchanged': True, 'databaseSHA256': after_database}
(target_root / 'work' / 'kiem_tra_dong_bo.json').write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'applied': True, 'changedFiles': len(changes), 'databaseUnchanged': True, 'backup': str(backup_path)}, ensure_ascii=False))
