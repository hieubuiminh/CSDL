from pathlib import Path
import re

root = Path(__file__).resolve().parents[2]
source = (root / 'database/he_thong_quan_ly_dang_ky_khai_tu.sql').read_text(encoding='utf-8-sig')
tables = {}
checks, uniques, edges = [], [], []
for name, body in re.findall(r'CREATE TABLE (\w+) \((.*?)\) ENGINE=InnoDB', source, re.S):
    columns = []
    for line in body.splitlines():
        line = line.strip().rstrip(',')
        match = re.match(r'(\w+) ((?:CHAR|VARCHAR|ENUM|DATE|DATETIME|TEXT)\b.*)', line)
        if match:
            column, definition = match.groups()
            columns.append((column, definition.replace('PRIMARY KEY', 'NOT NULL')))
        elif line.startswith('CONSTRAINT '):
            if ' CHECK ' in line:
                checks.append((name, line.split()[1], line))
            elif ' UNIQUE ' in line:
                uniques.append((name, re.search(r'UNIQUE \((\w+)\)', line)[1], line.split()[1]))
            elif ' FOREIGN KEY ' in line:
                edge = re.search(r'CONSTRAINT (\w+) FOREIGN KEY \((\w+)\) REFERENCES (\w+)\((\w+)\)', line)
                edges.append((name, *edge.groups()))
    tables[name] = columns
assert len(tables) == 9 and len(checks) == 6 and len(uniques) == 4 and len(edges) == 9

def quote(value):
    return "'" + value.replace("'", "''") + "'"

allowed = ','.join(map(quote, tables))
sql = []
def emit(text=''):
    sql.append(text)

def guard(query, message):
    emit('  IF EXISTS (' + query + ') THEN')
    emit("    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = " + quote(message) + ';')
    emit('  END IF;')

emit('''-- NANG CAP 9 BANG THEO BAO CAO; chon dung CSDL, sao luu va dung app truoc khi chay.
-- MySQL >= 8.0.16; mysql batch KHONG --force. File khong tu duoc thuc thi.
-- DDL tu COMMIT: loi giua chung khong the rollback toan file; giu app dung de xu ly.
-- Khong cat/xoa du lieu; chi chuyen nhan trang thai cu da biet, khong backfill sinh tu.
-- Khong sua App_User/bang ung dung; khong vo hieu hoa kiem tra khoa ngoai.
SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;
DELIMITER $$
DROP PROCEDURE IF EXISTS KT_Update_EnsureUnique$$
CREATE PROCEDURE KT_Update_EnsureUnique(IN p_table VARCHAR(64), IN p_column VARCHAR(64), IN p_name VARCHAR(64))
BEGIN
  DECLARE v_exists INT DEFAULT 0;
  IF NOT ((p_table='Ho_So_Khai_Tu' AND p_column IN ('CCCD_NgMat','SoGiayBaoTu'))
    OR (p_table='Can_Bo' AND p_column='CCCD') OR (p_table='An_Tang' AND p_column='SoGiayKhaiTu')) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Index nằm ngoài phạm vi nâng cấp.';
  END IF;
  SELECT COUNT(*) INTO v_exists FROM (
    SELECT INDEX_NAME FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME=p_table AND NON_UNIQUE=0
    GROUP BY INDEX_NAME HAVING COUNT(*)=1 AND MAX(COLUMN_NAME=p_column)=1
  ) equivalent_unique;
  IF v_exists=0 THEN
    SET @kt_update_sql=CONCAT('ALTER TABLE `',p_table,'` ADD CONSTRAINT `',REPLACE(p_name,'`','``'),'` UNIQUE (`',p_column,'`)');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END IF;
END$$
DROP PROCEDURE IF EXISTS KT_Update_ApDung$$
CREATE PROCEDURE KT_Update_ApDung()
BEGIN
  DECLARE v_major INT;
  DECLARE v_minor INT;
  DECLARE v_patch INT;
  DECLARE v_count INT DEFAULT 0;
  DECLARE v_done BOOLEAN DEFAULT FALSE;
  DECLARE v_table VARCHAR(64);
  DECLARE v_constraint VARCHAR(64);''')
emit(f'''  DECLARE fk_cursor CURSOR FOR
    SELECT DISTINCT TABLE_NAME,CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_NAME IN ({allowed})
    ORDER BY TABLE_NAME,CONSTRAINT_NAME;
  DECLARE check_cursor CURSOR FOR
    SELECT TABLE_NAME,CONSTRAINT_NAME FROM information_schema.TABLE_CONSTRAINTS
    WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='CHECK' AND (''')
emit('      ' + '\n      OR '.join(f"(TABLE_NAME={quote(table)} AND CONSTRAINT_NAME={quote(name)})" for table, name, _ in checks) + ')')
emit('''    ORDER BY TABLE_NAME,CONSTRAINT_NAME;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done=TRUE;

  IF DATABASE() IS NULL OR DATABASE()<>'quan_ly_dang_ky_khai_tu' THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Chỉ được nâng cấp CSDL quan_ly_dang_ky_khai_tu; hãy chọn lại.';
  END IF;
  SET v_major=CAST(SUBSTRING_INDEX(VERSION(),'.',1) AS UNSIGNED);
  SET v_minor=CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(),'.',2),'.',-1) AS UNSIGNED);
  SET v_patch=CAST(SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING_INDEX(VERSION(),'-',1),'.',3),'.',-1) AS UNSIGNED);
  IF VERSION() LIKE '%MariaDB%' OR v_major<8 OR (v_major=8 AND v_minor=0 AND v_patch<16) THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cần MySQL từ 8.0.16 để thực thi CHECK.';
  END IF;''')
emit(f'''  SELECT COUNT(*) INTO v_count FROM information_schema.TABLES
    WHERE TABLE_SCHEMA=DATABASE() AND TABLE_TYPE='BASE TABLE' AND ENGINE='InnoDB' AND TABLE_NAME IN ({allowed});
  IF v_count<>9 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Thiếu bảng gốc hoặc bảng không dùng InnoDB. Cần kiểm tra trước.';
  END IF;
  -- TAT CA PREFLIGHT truoc ALTER, DROP TRIGGER va chuyen nhan du lieu.''')

for table, columns in tables.items():
    terms = []
    for column, definition in columns:
        if 'NOT NULL' in definition:
            terms.append(f'{column} IS NULL')
        length = re.match(r'(?:VAR)?CHAR\((\d+)\)', definition)
        if length:
            terms.append(f'CHAR_LENGTH({column})>{length[1]}')
        if definition.startswith('TEXT'):
            terms.append(f'OCTET_LENGTH(CONVERT({column} USING utf8mb4))>65535')
    guard(f'SELECT 1 FROM {table} WHERE ' + '\n      OR '.join(terms), f'{table}: có NULL bắt buộc hoặc dữ liệu vượt độ dài đích; không tự cắt.')

for table, column in [('Cong_Dan','CCCD'),('Can_Bo','CCCD'),('Ho_So_Khai_Tu','CCCD_NgMat'),('Ho_So_Khai_Tu','CCCD_NgKhaiTu')]:
    guard(f"SELECT 1 FROM {table} WHERE CHAR_LENGTH({column})<>12 OR NOT REGEXP_LIKE({column},'^[0-9]{{12}}$','c')", f'{table}.{column}: phải đủ 12 chữ số ASCII.')
guard("SELECT 1 FROM Cong_Dan WHERE BINARY GioiTinh NOT IN (BINARY 'Nam',BINARY 'Nữ',BINARY 'Khác')", 'Giới tính không thuộc Nam/Nữ/Khác; không tự suy diễn.')
guard("SELECT 1 FROM Cong_Dan WHERE BINARY TrangThai NOT IN (BINARY 'Còn sống',BINARY 'Đang sống',BINARY 'Đã mất')", 'Trạng thái công dân lạ; chỉ hỗ trợ Còn sống/Đang sống/Đã mất.')
guard("SELECT 1 FROM Ho_So_Khai_Tu WHERE BINARY TrangThaiHoSo NOT IN (BINARY 'Đã duyệt',BINARY 'Chờ xử lý',BINARY 'Từ chối',BINARY 'Đã tiếp nhận',BINARY 'Đang xử lý',BINARY 'Chờ duyệt',BINARY 'Đã hoàn tất')", 'Trạng thái hồ sơ lạ; cần xem xét thủ công trước khi nâng cấp.')
for table, columns in tables.items():
    for column, definition in columns:
        if definition.startswith(('DATE ', 'DATETIME ')):
            guard(f'SELECT 1 FROM {table} WHERE YEAR({column})<1000 OR LAST_DAY({column}) IS NULL OR DAYOFMONTH({column})<1 OR DAYOFMONTH({column})>DAYOFMONTH(LAST_DAY({column}))', f'{table}.{column}: có ngày không hợp lệ.')
guard('SELECT 1 FROM Giay_Bao_Tu WHERE DATE(NgayGioMat)>NgayCap', 'Có ngày mất sau ngày cấp giấy báo tử.')
guard('SELECT 1 FROM Ho_So_Khai_Tu WHERE CCCD_NgKhaiTu=CCCD_NgMat', 'Có hồ sơ có người khai trùng người mất.')
def equal(left, right):
    return f'CONVERT({left} USING utf8mb4) COLLATE utf8mb4_unicode_ci=CONVERT({right} USING utf8mb4) COLLATE utf8mb4_unicode_ci'
guard('SELECT 1 FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON ' + equal('h.SoGiayBaoTu','g.SoGiayBaoTu') + ' WHERE g.NgayCap>h.NgayDangKi', 'Có hồ sơ đăng ký trước ngày cấp giấy báo tử.')

emit('  -- Duplicate va orphan duoc kiem tra theo collation DICH truoc khi doi kieu.')
for table, columns in tables.items():
    pk = columns[0][0]
    guard(f'SELECT 1 FROM {table} GROUP BY CONVERT({pk} USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1', f'{table}: khóa chính bị trùng ở utf8mb4_unicode_ci.')
for table, column, _ in uniques:
    guard(f'SELECT 1 FROM {table} GROUP BY CONVERT({column} USING utf8mb4) COLLATE utf8mb4_unicode_ci HAVING COUNT(*)>1', f'{table}.{column}: có giá trị trùng, chưa thể tạo UNIQUE.')
for table, _, column, parent, parent_column in edges:
    guard(f'SELECT 1 FROM {table} c LEFT JOIN {parent} p ON ' + equal('c.'+column, 'p.'+parent_column) + f' WHERE p.{parent_column} IS NULL', f'{table}.{column}: có khóa ngoại không tìm thấy bản ghi cha.')

# Reject custom incoming/outgoing/composite FKs instead of altering application tables.
edge_clauses = [f"(k.TABLE_NAME={quote(t)} AND k.COLUMN_NAME={quote(c)} AND k.REFERENCED_TABLE_NAME={quote(p)} AND k.REFERENCED_COLUMN_NAME={quote(pc)})" for t, _, c, p, pc in edges]
guard(f'''SELECT 1 FROM information_schema.KEY_COLUMN_USAGE k WHERE k.REFERENCED_TABLE_NAME IS NOT NULL
      AND ((k.TABLE_SCHEMA=DATABASE() AND k.TABLE_NAME IN ({allowed}))
        OR (k.REFERENCED_TABLE_SCHEMA=DATABASE() AND k.REFERENCED_TABLE_NAME IN ({allowed})))
      AND NOT (k.TABLE_SCHEMA=DATABASE() AND k.REFERENCED_TABLE_SCHEMA=DATABASE() AND (
        ''' + '\n        OR '.join(edge_clauses) + '))', 'Có FK tùy biến/ngoài 9 bảng gốc; cần migration riêng, không tự xóa.')
guard(f'''SELECT 1 FROM information_schema.KEY_COLUMN_USAGE WHERE CONSTRAINT_SCHEMA=DATABASE()
      AND REFERENCED_TABLE_NAME IS NOT NULL AND TABLE_NAME IN ({allowed})
      GROUP BY TABLE_NAME,CONSTRAINT_NAME HAVING COUNT(*)<>1''', 'Có FK nhiều cột ngoài đặc tả; cần migration riêng.')

owned_triggers = [
    ('KT_Update_HoSo_BI','Ho_So_Khai_Tu','BEFORE','INSERT'),
    ('KT_Update_HoSo_BU','Ho_So_Khai_Tu','BEFORE','UPDATE'),
    ('KT_Update_GiayBaoTu_BU','Giay_Bao_Tu','BEFORE','UPDATE'),
    ('KT_Update_HoSo_AI','Ho_So_Khai_Tu','AFTER','INSERT'),
    ('KT_Update_HoSo_AU','Ho_So_Khai_Tu','AFTER','UPDATE')
]
trigger_allow = ' OR '.join(f'(TRIGGER_NAME={quote(n)} AND EVENT_OBJECT_TABLE={quote(t)} AND ACTION_TIMING={quote(a)} AND EVENT_MANIPULATION={quote(e)})' for n,t,a,e in owned_triggers)
guard(f'SELECT 1 FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() AND EVENT_OBJECT_TABLE IN ({allowed}) AND NOT ({trigger_allow})', 'Có trigger tùy biến trên bảng gốc; cần xem xét, không tự thay thế.')
check_allow = ' OR '.join(f'(TABLE_NAME={quote(t)} AND CONSTRAINT_NAME={quote(n)})' for t,n,_ in checks)
guard(f"SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME IN ({allowed}) AND CONSTRAINT_TYPE='CHECK' AND NOT ({check_allow})", 'Có CHECK tùy biến trên bảng gốc; cần xem xét trước khi đổi kiểu.')
for table, name, _, _, _ in edges:
    guard(f"SELECT 1 FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND CONSTRAINT_TYPE='FOREIGN KEY' AND CONSTRAINT_NAME={quote(name)} AND TABLE_NAME<>{quote(table)}", 'Tên FK đích đang được bảng khác sử dụng; cần xử lý riêng.')
for table, column, name in uniques:
    guard(f"SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME={quote(table)} AND INDEX_NAME={quote(name)} GROUP BY INDEX_NAME HAVING COUNT(*)<>1 OR MAX(NON_UNIQUE)<>0 OR MAX(COLUMN_NAME={quote(column)})<>1", f'Index {name} đã có nhưng khác định nghĩa đích.')

# Require exactly the existing single-column primary keys, preserving their identity.
pk_clauses = [f"(TABLE_NAME={quote(t)} AND MAX(COLUMN_NAME={quote(cols[0][0])})=1)" for t, cols in tables.items()]
emit(f'''  SELECT COUNT(*) INTO v_count FROM (
    SELECT TABLE_NAME FROM information_schema.STATISTICS WHERE TABLE_SCHEMA=DATABASE()
      AND INDEX_NAME='PRIMARY' AND TABLE_NAME IN ({allowed})
    GROUP BY TABLE_NAME HAVING COUNT(*)=1 AND (''' + '\n      OR '.join(pk_clauses) + ''')
  ) valid_primary;
  IF v_count<>9 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Khóa chính khác schema gốc; không tự thay cấu trúc tùy biến.';
  END IF;''')

emit('''
  -- PREFLIGHT DAT. DDL tu day co the commit; giu app dung cho den khi thanh cong.
  DROP TRIGGER IF EXISTS KT_Update_HoSo_BI;
  DROP TRIGGER IF EXISTS KT_Update_HoSo_BU;
  DROP TRIGGER IF EXISTS KT_Update_GiayBaoTu_BU;
  DROP TRIGGER IF EXISTS KT_Update_HoSo_AI;
  DROP TRIGGER IF EXISTS KT_Update_HoSo_AU;
  SET v_done=FALSE;
  OPEN fk_cursor;
  fk_loop: LOOP
    FETCH fk_cursor INTO v_table,v_constraint;
    IF v_done THEN LEAVE fk_loop; END IF;
    SET @kt_update_sql=CONCAT('ALTER TABLE `',REPLACE(v_table,'`','``'),'` DROP FOREIGN KEY `',REPLACE(v_constraint,'`','``'),'`');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END LOOP;
  CLOSE fk_cursor;
  SET v_done=FALSE;
  OPEN check_cursor;
  check_loop: LOOP
    FETCH check_cursor INTO v_table,v_constraint;
    IF v_done THEN LEAVE check_loop; END IF;
    SET @kt_update_sql=CONCAT('ALTER TABLE `',REPLACE(v_table,'`','``'),'` DROP CHECK `',REPLACE(v_constraint,'`','``'),'`');
    PREPARE kt_update_statement FROM @kt_update_sql;
    EXECUTE kt_update_statement;
    DEALLOCATE PREPARE kt_update_statement;
  END LOOP;
  CLOSE check_cursor;

  -- Chi doi nhan da biet. Khong sua backlog Da mat tu ho so cu.
  UPDATE Cong_Dan SET TrangThai='Còn sống' WHERE BINARY TrangThai=BINARY 'Đang sống';
  UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Chờ xử lý'
    WHERE BINARY TrangThaiHoSo IN (BINARY 'Đã tiếp nhận',BINARY 'Đang xử lý',BINARY 'Chờ duyệt');
  UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Đã duyệt' WHERE BINARY TrangThaiHoSo=BINARY 'Đã hoàn tất';
''')
for table, columns in tables.items():
    emit(f'  ALTER TABLE {table} CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci,')
    emit('    ' + ',\n    '.join(f'MODIFY {c} {d}' for c, d in columns) + ';')
for table, column, name in uniques:
    emit(f'  CALL KT_Update_EnsureUnique({quote(table)},{quote(column)},{quote(name)});')
for table, _, definition in checks:
    emit(f'  ALTER TABLE {table} ADD {definition};')
emit('  -- Bo qua ON UPDATE/DELETE giu RESTRICT/NO ACTION mac dinh, khong CASCADE.')
for table, name, column, parent, parent_column in edges:
    emit(f'  ALTER TABLE {table} ADD CONSTRAINT {name} FOREIGN KEY ({column}) REFERENCES {parent}({parent_column});')
emit('''END$$
CALL KT_Update_ApDung()$$
DROP PROCEDURE KT_Update_ApDung$$
DROP PROCEDURE KT_Update_EnsureUnique$$
''')
trigger_source = source[source.index('CREATE TRIGGER KT_Update_HoSo_BI'):]
trigger_source = trigger_source[:trigger_source.index('DELIMITER ;')]
# Explicit NOT FOUND handling for unreferenced certificates; FK rejects missing parents.
trigger_parts = re.split(r'(?=CREATE TRIGGER )', trigger_source)
for index, part in enumerate(trigger_parts):
    if part.startswith('CREATE TRIGGER ') and 'DECLARE CONTINUE HANDLER FOR NOT FOUND' not in part:
        trigger_parts[index] = re.sub(r'DECLARE (v_ngay_(?:cap|dang_ky)) DATE(?: DEFAULT NULL)?;',
            lambda match: f'DECLARE {match[1]} DATE DEFAULT NULL;\n  DECLARE CONTINUE HANDLER FOR NOT FOUND SET {match[1]}=NULL;', part)
trigger_source = ''.join(trigger_parts)
emit(trigger_source.strip())
emit('''DELIMITER ;
SELECT VERSION() AS PhienBanMySQL;
-- Chi thong bao backlog; chi ho so KHONG tu choi moi duoc tinh o day.
SELECT COUNT(DISTINCT c.CCCD) AS SoCongDanCoHoSoHopLeNhungChuaDanhDauDaMat
FROM Cong_Dan c JOIN Ho_So_Khai_Tu h ON h.CCCD_NgMat=c.CCCD
WHERE h.TrangThaiHoSo<>'Từ chối' AND c.TrangThai<>'Đã mất';
SELECT 'Đã nâng cấp 9 bảng, chuẩn hóa nhãn đã biết và cài 5 trigger; không tự sửa backlog sinh tử.' AS KetQua;''')
# Trigger DDL must be OUTSIDE stored routines. Run all preflight first, then
# replace only the five owned triggers and invoke the DDL application routine.
full = '\n'.join(sql)+'\n'
main_marker = 'DROP PROCEDURE IF EXISTS KT_Update_ApDung$$'
prefix, rest = full.split(main_marker, 1)
routine, suffix = rest.split('END$$\nCALL KT_Update_ApDung()$$', 1)
declarations, body = routine.split('  IF DATABASE() IS NULL', 1)
declarations = declarations.split('BEGIN\n', 1)[1]
preflight, apply_body = ('  IF DATABASE() IS NULL'+body).split('  -- PREFLIGHT DAT.', 1)
apply_body = apply_body[apply_body.index('  SET v_done=FALSE;'):]

# Read one current FK/CHECK name per iteration instead of holding metadata
# cursors open across ALTER's implicit commits.
fk_query = re.search(r'DECLARE fk_cursor CURSOR FOR\n(.*?);', declarations, re.S)[1].strip()
check_query = re.search(r'DECLARE check_cursor CURSOR FOR\n(.*?);', declarations, re.S)[1].strip()
declarations = re.sub(r'  DECLARE (?:fk|check)_cursor CURSOR FOR\n.*?;\n', '', declarations, flags=re.S)
for kind, query in [('fk', fk_query), ('check', check_query)]:
    pattern = rf'  SET v_done=FALSE;\n  OPEN {kind}_cursor;\n  {kind}_loop: LOOP\n    FETCH {kind}_cursor INTO v_table,v_constraint;\n    IF v_done THEN LEAVE {kind}_loop; END IF;\n(.*?)  END LOOP;\n  CLOSE {kind}_cursor;'
    ddl = re.search(pattern, apply_body, re.S)[1]
    select = query.replace('SELECT DISTINCT TABLE_NAME,CONSTRAINT_NAME FROM', 'SELECT TABLE_NAME,CONSTRAINT_NAME INTO v_table,v_constraint FROM').replace('SELECT TABLE_NAME,CONSTRAINT_NAME FROM', 'SELECT TABLE_NAME,CONSTRAINT_NAME INTO v_table,v_constraint FROM')
    replacement = f'  {kind}_loop: LOOP\n    SET v_done=FALSE;\n    {select} LIMIT 1;\n    IF v_done THEN LEAVE {kind}_loop; END IF;\n' + ddl + '  END LOOP;'
    apply_body = re.sub(pattern, lambda _: replacement, apply_body, flags=re.S)
full = prefix + '''DROP PROCEDURE IF EXISTS KT_Update_Preflight$$
CREATE PROCEDURE KT_Update_Preflight()
BEGIN
  DECLARE v_major INT;
  DECLARE v_minor INT;
  DECLARE v_patch INT;
  DECLARE v_count INT DEFAULT 0;
''' + preflight + 'END$$\n' + main_marker + '\nCREATE PROCEDURE KT_Update_ApDung()\nBEGIN\n' + declarations + apply_body + '''END$$
CALL KT_Update_Preflight()$$
-- PREFLIGHT DAT. Cac lenh DROP/CREATE TRIGGER tinh nam ngoai procedure.
DROP TRIGGER IF EXISTS KT_Update_HoSo_BI$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_BU$$
DROP TRIGGER IF EXISTS KT_Update_GiayBaoTu_BU$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AI$$
DROP TRIGGER IF EXISTS KT_Update_HoSo_AU$$
CALL KT_Update_ApDung()$$
DROP PROCEDURE KT_Update_Preflight$$
''' + suffix
(root / 'database/cap_nhat_rang_buoc.sql').write_text(full, encoding='utf-8')
print('Wrote migration:', len(full.splitlines()), 'lines; 9 tables, 6 checks, 4 uniques, 9 FKs, 5 triggers.')
