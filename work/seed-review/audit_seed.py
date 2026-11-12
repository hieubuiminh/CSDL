from pathlib import Path
from collections import Counter, defaultdict
from datetime import date, datetime
import ast, re, json, unicodedata

root = Path(__file__).resolve().parents[2]
source = (root / 'du_lieu_mau.sql').read_text(encoding='utf-8-sig')
rows, headers = {}, {}
for match in re.finditer(r'INSERT\s+INTO\s+(\w+)\s*\((.*?)\)\s*VALUES\s*(.*?);', source, re.S | re.I):
    table, header, body = match.groups()
    columns = [column.strip() for column in header.split(',')]
    parsed = []
    for line in body.splitlines():
        line = line.strip().rstrip(',;')
        if not line or line.startswith('--'): continue
        if not line.startswith('(') or not line.endswith(')'): raise ValueError('Expected one row per line')
        value = ast.literal_eval(re.sub(r'\bNULL\b', 'None', line))
        if len(value) != len(columns): raise ValueError('Column count mismatch')
        parsed.append(dict(zip(columns, value)))
    rows[table], headers[table] = parsed, columns
assert len(rows) == 9
notices = {row['SoGiayBaoTu']: row for row in rows['Giay_Bao_Tu']}
for row in rows['Ho_So_Khai_Tu']:
    row['CCCD_NgMat'] = notices.get(row['SoGiayBaoTu'], {}).get('CCCD_NgMat')
main = (root / 'database/he_thong_quan_ly_dang_ky_khai_tu.sql').read_text(encoding='utf-8-sig')
schema, primary = {}, {}
for table, body in re.findall(r'CREATE TABLE (\w+) \((.*?)\) ENGINE=InnoDB', main, re.S):
    schema[table] = {}
    for line in body.splitlines():
        field = re.match(r'(\w+) ((?:CHAR|VARCHAR|ENUM|DATE|DATETIME|TEXT)\b.*)', line.strip().rstrip(','))
        if field:
            schema[table][field[1]] = field[2]
            if 'PRIMARY KEY' in field[2]: primary[table] = field[1]
violations, ordinals = Counter(), defaultdict(list)
def flag(label, table, index):
    violations[label] += 1
    ordinals[label].append(f'{table}#{index}')
def fold(value):
    if value is None: return None
    return ''.join(c for c in unicodedata.normalize('NFD', str(value).casefold().replace('đ','d')) if not unicodedata.combining(c)).rstrip(' ')
for table, records in rows.items():
    for index, row in enumerate(records, 1):
        for column, definition in schema[table].items():
            value = row.get(column)
            if value is None:
                if 'NOT NULL' in definition or 'PRIMARY KEY' in definition: flag('required_null', table, index)
                continue
            limit = re.match(r'(?:VAR)?CHAR\((\d+)\)', definition)
            if limit and len(str(value)) > int(limit[1]): flag('over_length', table, index)
            if definition.startswith('TEXT') and len(str(value).encode()) > 65535: flag('over_text_bytes', table, index)
            if definition.startswith(('DATE ', 'DATETIME ')):
                try: datetime.fromisoformat(value) if definition.startswith('DATETIME') else date.fromisoformat(value)
                except (ValueError, TypeError): flag('invalid_date', table, index)
        if table in ('Cong_Dan','Can_Bo') and not re.fullmatch(r'[0-9]{12}',str(row['CCCD'])): flag('cccd_invalid',table,index)
        if table == 'Cong_Dan':
            if row['GioiTinh'] not in ('Nam','Nữ','Khác'): flag('gender_invalid',table,index)
            if row['TrangThai'] not in ('Còn sống','Đã mất'): flag('citizen_status_needs_mapping',table,index)
        if table == 'Ho_So_Khai_Tu' and row['TrangThaiHoSo'] not in ('Đã duyệt','Chờ xử lý','Từ chối'): flag('file_status_needs_mapping',table,index)
    columns = [primary[table]] + {'Can_Bo':['CCCD'],'Ho_So_Khai_Tu':['CCCD_NgMat','SoGiayBaoTu'],'An_Tang':['SoGiayKhaiTu']}.get(table,[])
    for column in columns:
        duplicate_count = sum(count-1 for count in Counter(fold(row.get(column)) for row in records).values() if count > 1)
        if duplicate_count: violations[f'duplicate_{table}_{column}'] += duplicate_count
edges = [('Can_Bo','MaUBND','UBND','MaUBND'),('Giay_Bao_Tu','MaNguyenNhan','Nguyen_Nhan','MaNguyenNhan'),('Giay_Bao_Tu','MaXaPhuong','Noi_Mat','MaXaPhuong'),('Giay_Bao_Tu','MaCSYT','CSYT','MaCSYT'),('Ho_So_Khai_Tu','SoGiayBaoTu','Giay_Bao_Tu','SoGiayBaoTu'),('Ho_So_Khai_Tu','CCCD_NgMat','Cong_Dan','CCCD'),('Ho_So_Khai_Tu','CCCD_NgKhaiTu','Cong_Dan','CCCD'),('Ho_So_Khai_Tu','MaCanBoTiepNhan','Can_Bo','MaCanBo'),('An_Tang','SoGiayKhaiTu','Ho_So_Khai_Tu','SoGiayKhaiTu')]
for child,column,parent,parent_column in edges:
    valid = {fold(row[parent_column]) for row in rows[parent]}
    for index,row in enumerate(rows[child],1):
        if fold(row.get(column)) not in valid: flag(f'orphan_{child}_{column}',child,index)
citizens = {row['CCCD']:row for row in rows['Cong_Dan']}
files = {row['SoGiayKhaiTu']:row for row in rows['Ho_So_Khai_Tu']}
for index,row in enumerate(rows['Giay_Bao_Tu'],1):
    if row['NgayGioMat'][:10] > row['NgayCap']: flag('death_after_notice_issue','Giay_Bao_Tu',index)
    person = citizens.get(row.get('CCCD_NgMat'))
    if person and person['NgaySinh'] > row['NgayGioMat'][:10]: flag('birth_after_death','Giay_Bao_Tu',index)
for index,row in enumerate(rows['Ho_So_Khai_Tu'],1):
    notice = notices.get(row['SoGiayBaoTu'])
    if notice and notice['NgayCap'] > row['NgayDangKi']: flag('issue_after_registration','Ho_So_Khai_Tu',index)
    if row['CCCD_NgMat'] == row['CCCD_NgKhaiTu']: flag('applicant_equals_deceased','Ho_So_Khai_Tu',index)
    person = citizens.get(row['CCCD_NgKhaiTu'])
    if person and person['NgaySinh'] > row['NgayDangKi']: flag('applicant_birth_after_registration','Ho_So_Khai_Tu',index)
for index,row in enumerate(rows['An_Tang'],1):
    file = files.get(row['SoGiayKhaiTu'])
    notice = notices.get(file['SoGiayBaoTu']) if file else None
    if notice and row['NgayAnTang'] < notice['NgayGioMat'][:10]: flag('burial_before_death','An_Tang',index)
nonrefused = {row['CCCD_NgMat'] for row in rows['Ho_So_Khai_Tu'] if row['TrangThaiHoSo'] != 'Từ chối'}
summary = {
    'counts': {table:len(records) for table,records in rows.items()},
    'extra_columns': {table:[col for col in fields if col not in schema[table]] for table,fields in headers.items() if any(col not in schema[table] for col in fields)},
    'missing_columns': {table:[col for col in schema[table] if col not in fields] for table,fields in headers.items() if any(col not in fields for col in schema[table])},
    'virtual_deceased_mapping_missing': sum(row['CCCD_NgMat'] is None for row in rows['Ho_So_Khai_Tu']),
    'citizen_statuses': dict(Counter(row['TrangThai'] for row in rows['Cong_Dan'])),
    'file_statuses': dict(Counter(row['TrangThaiHoSo'] for row in rows['Ho_So_Khai_Tu'])),
    'violations_after_virtual_structure_fix': dict(violations),
    'violation_ordinals': {key:value[:12] for key,value in ordinals.items()},
    'nonrefused_citizens_not_dead_before_trigger': sum(citizens[cccd]['TrangThai'] != 'Đã mất' for cccd in nonrefused if cccd in citizens),
    'death_years': dict(Counter(row['NgayGioMat'][:4] for row in rows['Giay_Bao_Tu'])),
    'notice_date_range': [min(row['NgayCap'] for row in rows['Giay_Bao_Tu']),max(row['NgayCap'] for row in rows['Giay_Bao_Tu'])]
}
print(json.dumps(summary,ensure_ascii=True,indent=2))
