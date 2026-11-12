"""Verify the authoritative new schema and unchanged sample rows in isolated MySQL.

Only canonical project SQL is executed. The original tao_bang.sql containing DROP
DATABASE is hashed, never executed. Reports contain counts and digests, not citizen rows.
"""
from __future__ import annotations

import argparse
from collections import Counter
import datetime as dt
from decimal import Decimal, ROUND_HALF_UP
import hashlib
import importlib.util
import json
import pathlib
import re
import sys
import uuid

from check_sample_data import SeedReview, TABLES
from sql_report_check import Harness, ROOT, quote

NEW_DB = 'quan_li_khai_tu'


def load_expected(source):
    spec = importlib.util.spec_from_file_location('seed_parser_for_review', ROOT / 'work/seed-review/prepare_seed.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    data = module.parse_inserts(source.read_text(encoding='utf-8-sig'))
    expected = {}
    for table, item in data.items():
        rows = sorted(([row[column] for column in item['columns']] for row in item['rows']), key=lambda row: row[0])
        digest = hashlib.sha256(json.dumps(rows, ensure_ascii=False, separators=(',', ':')).encode()).hexdigest()
        expected[table] = {'count': len(rows), 'columns': item['columns'], 'sha256': digest}
    return data, expected


def statements(source):
    """Split SQL while preserving quoted semicolons and discarding comments."""
    parts, buffer = [], []
    index, quoted = 0, None
    while index < len(source):
        char = source[index]
        if quoted:
            buffer.append(char)
            if char == '\\' and index + 1 < len(source):
                index += 1
                buffer.append(source[index])
            elif char == quoted:
                if index + 1 < len(source) and source[index + 1] == quoted:
                    index += 1
                    buffer.append(source[index])
                else:
                    quoted = None
        elif char in "'\"`":
            quoted = char
            buffer.append(char)
        elif source.startswith('--', index):
            end = source.find('\n', index)
            index = len(source) if end < 0 else end
            buffer.append('\n')
            continue
        elif source.startswith('/*', index):
            end = source.find('*/', index + 2)
            if end < 0:
                raise ValueError('Unterminated SQL comment')
            index = end + 2
            continue
        elif char == ';':
            if ''.join(buffer).strip():
                parts.append(''.join(buffer).strip())
            buffer = []
        else:
            buffer.append(char)
        index += 1
    if ''.join(buffer).strip():
        parts.append(''.join(buffer).strip())
    return parts


class NewHarness(Harness):
    def __init__(self, args):
        super().__init__(args)
        self.name = 'khai-tu-new-schema-review-' + uuid.uuid4().hex[:10]
        self.state_file = ROOT / 'work/new-schema-review/running-container.json'

    def start(self):
        self.state_file.parent.mkdir(parents=True, exist_ok=True)
        self.state_file.write_text(json.dumps({'name': self.name, 'label': self.label_value, 'removed': False}), encoding='utf-8')
        print('Owned disposable container: ' + self.name, flush=True)
        super().start()

    def sql(self, text, use_database=True):
        self.owned()
        command = ['exec', '-i', '-e', 'MYSQL_PWD=' + self.password, self.name,
                   'mysql', '-uroot', '--default-character-set=utf8mb4', '--batch', '--raw', '--skip-column-names']
        if use_database:
            command.append(NEW_DB)
        return self.docker(*command, data=text.encode('utf-8'))

    def reset(self):
        self.owned()
        result = self.sql(f'DROP DATABASE IF EXISTS {NEW_DB}; CREATE DATABASE {NEW_DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;', False)
        if result.returncode:
            raise RuntimeError('Cannot initialize the owned test database.')

    def close(self):
        super().close()
        if self.metadata.get('container_removed'):
            self.state_file.write_text(json.dumps({'name': self.name, 'label': self.label_value, 'removed': True}), encoding='utf-8')


def insert(table, columns, values):
    return f"INSERT INTO {table} ({','.join(columns)}) VALUES ({','.join(map(quote, values))});\n"


def citizen(identity):
    return insert('Cong_Dan', ['CCCD', 'HoTen', 'NgaySinh', 'GioiTinh'], [identity, 'Nguoi thu', '1980-01-01', 'Nam'])


def notice(identifier='TSGBT', deceased='990000000001', issued='2026-08-02'):
    return insert('Giay_Bao_Tu', ['SoGiayBaoTu', 'NgayCap', 'NgayGioMat', 'CCCD_NgMat', 'MaCSYT', 'MaNguyenNhan', 'MaXaPhuong'],
                  [identifier, issued, '2026-08-01 12:00:00', deceased, 'TSCS', 'TSNN', 'TSXA'])


def record(identifier='TSKT', certificate='TSGBT', applicant='990000000002', status='Đã duyệt', day='2026-08-03'):
    columns = ['SoGiayKhaiTu', 'SoGiayBaoTu', 'NgayDangKi', 'CCCD_NgKhaiTu', 'QuanHe', 'MaCanBoTiepNhan']
    values = [identifier, certificate, day, applicant, 'Con', 'TSCB']
    if status is not None:
        columns.append('TrangThaiHoSo')
        values.append(status)
    return insert('Ho_So_Khai_Tu', columns, values)


def graph(status='Đã duyệt'):
    return ''.join(citizen(f'99000000000{index}') for index in (1, 2, 3)) + notice() + record(status=status)


class NewSchemaReview(SeedReview):
    def __init__(self, args, data):
        super().__init__(args)
        self.harness = NewHarness(args)
        self.data = data

    def constraints(self):
        for kind, expected in [('FOREIGN KEY', 9), ('CHECK', 7), ('UNIQUE', 4)]:
            actual = int(self.execute("SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME<>'App_User' AND CONSTRAINT_TYPE='" + kind + "';", 'inspect constraints'))
            self.result('new-schema constraint count: ' + kind, actual == expected, expected=expected, actual=actual)
        actual = int(self.execute('SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE();', 'inspect triggers'))
        self.result('six cross-table integrity triggers are installed', actual == 6, actual=actual)
        shape = self.execute("SELECT SUM(TABLE_NAME='Giay_Bao_Tu'),SUM(TABLE_NAME='Ho_So_Khai_Tu') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND COLUMN_NAME='CCCD_NgMat';", 'inspect deceased owner')
        self.result('deceased identity belongs only to Giay_Bao_Tu', shape == '1\t0')
        violations = {
            'self_applicant': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE h.CCCD_NgKhaiTu=g.CCCD_NgMat;',
            'death_after_issue': 'SELECT COUNT(*) FROM Giay_Bao_Tu WHERE DATE(NgayGioMat)>NgayCap;',
            'issue_after_registration': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE g.NgayCap>h.NgayDangKi;',
            'death_before_birth': 'SELECT COUNT(*) FROM Giay_Bao_Tu g JOIN Cong_Dan c ON c.CCCD=g.CCCD_NgMat WHERE c.NgaySinh>DATE(g.NgayGioMat);',
            'burial_before_death': 'SELECT COUNT(*) FROM An_Tang a JOIN Ho_So_Khai_Tu h ON h.SoGiayKhaiTu=a.SoGiayKhaiTu JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE a.NgayAnTang<DATE(g.NgayGioMat);',
        }
        counts = {name: int(self.execute(sql, 'sample integrity ' + name)) for name, sql in violations.items()}
        self.metadata['integrity_violation_counts'] = counts
        self.result('sample chronology and distinct-person rules are consistent', not any(counts.values()), counts=counts)
        self.result('no application accounts are seeded', self.execute('SELECT COUNT(*) FROM App_User;', 'account count') == '0')

    def check_reports(self):
        prelude = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci; SET time_zone='+07:00'; SET timestamp=UNIX_TIMESTAMP('2026-11-10 12:00:00');\n"
        outputs = []
        for sql in statements(self.args.queries.read_text(encoding='utf-8-sig')):
            if re.match(r'^(SELECT|WITH)\b', sql, re.I):
                text = self.execute(prelude + sql + ';', 'execute report query ' + str(len(outputs) + 1))
                outputs.append([line.split('\t') for line in text.splitlines()] if text else [])
            else:
                prelude += sql + ';\n'
        self.result('exactly seven report queries execute', len(outputs) == 7)
        if len(outputs) != 7:
            return
        people = {row['CCCD']: row for row in self.data['Cong_Dan']['rows']}
        notices = {row['SoGiayBaoTu']: row for row in self.data['Giay_Bao_Tu']['rows']}
        records = self.data['Ho_So_Khai_Tu']['rows']
        self.result('query 1 returns the requested sample certificate', len(outputs[0]) == 1 and len(outputs[0][0]) == 8)
        expected_gender = Counter(row['GioiTinh'] for row in people.values() if row['TrangThai'] == 'Đã mất')
        actual_gender = {row[0]: int(row[1]) for row in outputs[1]}
        self.result('query 2 counts every deceased citizen', actual_gender == dict(expected_gender), total=sum(actual_gender.values()))
        listing = outputs[2]
        self.result('query 3 lists all 100 records in ascending order', len(listing) == len(records) and [(row[3], row[0]) for row in listing] == sorted((row[3], row[0]) for row in listing))
        wards = {row['MaXaPhuong']: 0 for row in self.data['Noi_Mat']['rows']}
        for row in records:
            if row['TrangThaiHoSo'] != 'Từ chối' and row['NgayDangKi'].startswith('2026-'):
                wards[notices[row['SoGiayBaoTu']]['MaXaPhuong']] += 1
        area = {row[0]: int(row[2]) for row in outputs[3]}
        self.result('query 4 keeps all areas and excludes rejected records', area == wards, areas=len(area), registered=sum(area.values()))
        ages, causes = Counter(), {}
        for row in records:
            if row['TrangThaiHoSo'] != 'Đã duyệt':
                continue
            death_notice = notices[row['SoGiayBaoTu']]
            death = dt.datetime.fromisoformat(death_notice['NgayGioMat']).date()
            birth = dt.date.fromisoformat(people[death_notice['CCCD_NgMat']]['NgaySinh'])
            age = death.year-birth.year-((death.month, death.day)<(birth.month, birth.day))
            group = 'Dưới 18' if age < 18 else '18–60' if age <= 60 else 'Trên 60'
            ages[group] += 1
            causes.setdefault(group, Counter())[death_notice['MaNguyenNhan']] += 1
        cause_names = {row['MaNguyenNhan']: row['TenNguyenNhan'] for row in self.data['Nguyen_Nhan']['rows']}
        expected_age = {(group, str(ages[group]), cause_names[cause], str(count)) for group, values in causes.items() for cause, count in values.items() if count == max(values.values())}
        self.result('query 5 counts approved records and every leading-cause tie', {tuple(row) for row in outputs[4]} == expected_age, approved_total=sum(ages.values()), age_group_totals=dict(ages))
        expected_hospitals = {}
        for hospital in self.data['CSYT']['rows']:
            selected = [row for row in notices.values() if row['MaCSYT'] == hospital['MaCSYT'] and '2026-07-01' <= row['NgayCap'] < '2026-10-01']
            if len(selected) <= 50:
                continue
            onsite = sum(hospital['TenCSYT'].casefold() in (row['NoiMatChiTiet'] or '').casefold() or hospital['DiaChi'].casefold() in (row['NoiMatChiTiet'] or '').casefold() for row in selected)
            rate = Decimal(100*onsite)/Decimal(len(selected))
            expected_hospitals[hospital['MaCSYT']] = (len(selected), onsite, rate.quantize(Decimal('.01'), rounding=ROUND_HALF_UP))
        actual_hospitals = {row[0]: (int(row[2]), int(row[3]), Decimal(row[4])) for row in outputs[5]}
        self.result('query 6 previous-quarter threshold and estimated ratios match the sample', actual_hospitals == expected_hospitals,
                    eligible_counts={key: value[0] for key, value in actual_hospitals.items()})
        expected_years = dict(Counter(int(row['NgayGioMat'][:4]) for row in notices.values()))
        actual_years = {int(row[0]): int(row[1]) for row in outputs[6]}
        self.result('query 7 counts all death notices by death year', actual_years == expected_years, years=actual_years)

    def invalid_cases(self):
        fixtures = "INSERT INTO Nguyen_Nhan VALUES ('TSNN','Nguyen nhan thu'); INSERT INTO Noi_Mat VALUES ('TSXA','Xa thu'); INSERT INTO CSYT VALUES ('TSCS','Co so thu','Dia chi thu','0000000000'); INSERT INTO UBND VALUES ('TSUB','UBND thu','Phường','Dia chi thu','0000000000'); INSERT INTO Can_Bo VALUES ('TSCB','990000000901','Can bo thu','Ho tich','0000000000','TSUB');"
        self.execute(fixtures, 'synthetic constraint fixtures')
        h, phase = self.harness, 'new-schema'
        h.case(phase, 'default pending state marks non-rejected deceased', graph(None) + "SELECT h.TrangThaiHoSo,c.TrangThai FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu JOIN Cong_Dan c ON c.CCCD=g.CCCD_NgMat WHERE h.SoGiayKhaiTu='TSKT';", expected='Chờ xử lý\tĐã mất')
        h.case(phase, 'rejected insert does not mark deceased', graph('Từ chối') + "SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Còn sống')
        h.case(phase, 'approval update marks deceased', graph('Từ chối') + "UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Đã duyệt' WHERE SoGiayKhaiTu='TSKT'; SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Đã mất')
        for name, sql, codes in [
            ('insert rejects self-applicant', citizen('990000000001')+notice()+record(applicant='990000000001'), (1644,)),
            ('update rejects self-applicant', graph()+"UPDATE Ho_So_Khai_Tu SET CCCD_NgKhaiTu='990000000001' WHERE SoGiayKhaiTu='TSKT';", (1644,)),
            ('insert rejects registration before issue', citizen('990000000001')+citizen('990000000002')+notice()+record(day='2026-08-01'), (1644,)),
            ('update rejects registration before issue', graph()+"UPDATE Ho_So_Khai_Tu SET NgayDangKi='2026-08-01' WHERE SoGiayKhaiTu='TSKT';", (1644,)),
            ('notice update rejects issue after registration', graph()+"UPDATE Giay_Bao_Tu SET NgayCap='2026-08-04' WHERE SoGiayBaoTu='TSGBT';", (1644,)),
            ('notice update rejects deceased matching linked applicant', graph()+"UPDATE Giay_Bao_Tu SET CCCD_NgMat='990000000002' WHERE SoGiayBaoTu='TSGBT';", (1644,)),
            ('one notice per deceased', citizen('990000000001')+notice()+notice('TSGBT2'), (1062,)),
            ('one registration per notice', graph()+record('TSKT2'), (1062,)),
            ('officer identity remains unique', "INSERT INTO Can_Bo VALUES ('TSCB2','990000000901','Can bo thu','Ho tich','0000000000','TSUB');", (1062,)),
            ('death after issue is rejected', citizen('990000000001')+notice(issued='2026-07-31'), (3819,)),
            ('non-ASCII identity is rejected', citizen('９９０００００００００１'), (3819,)),
            ('21-character notice ID is rejected', citizen('990000000001')+notice('T'*21), (1406,)),
        ]:
            h.case(phase, name, sql, True, codes)
        h.case(phase, 'notice deceased change marks the new citizen', graph()+"UPDATE Giay_Bao_Tu SET CCCD_NgMat='990000000003' WHERE SoGiayBaoTu='TSGBT'; SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000003';", expected='Đã mất')
        h.case(phase, 'notice deceased change for rejected record leaves citizen living', graph('Từ chối')+"UPDATE Giay_Bao_Tu SET CCCD_NgMat='990000000003' WHERE SoGiayBaoTu='TSGBT'; SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000003';", expected='Còn sống')

    def run(self):
        self.harness.start()
        self.harness.reset()
        ddl = self.args.schema.read_text(encoding='utf-8-sig')
        if re.search(r'\bDROP\s+DATABASE\b', '\n'.join(line for line in ddl.splitlines() if not line.lstrip().startswith('--')), re.I):
            raise RuntimeError('Refusing to execute canonical DDL containing DROP DATABASE.')
        for name, file in [('canonical schema', self.args.schema), ('unchanged sample data', self.args.standalone), ('account setup', self.args.setup)]:
            self.execute(file.read_text(encoding='utf-8-sig'), name)
            self.result(name + ' imports successfully', True)
        snapshot = self.snapshot()
        self.snapshots.append(snapshot)
        for table in TABLES:
            expected = self.args.expected[table]
            self.result(table + ': raw sample count and column values are unchanged', snapshot[table]['rows'] == expected['count'] and snapshot[table]['sha256'] == expected['sha256'], count=snapshot[table]['rows'])
        self.constraints()
        self.check_reports()
        self.invalid_cases()
        self.results.extend(self.harness.results)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true')
    parser.add_argument('--image', default='mysql:8.0')
    parser.add_argument('--schema', type=pathlib.Path, default=ROOT / 'database/tao_bang.sql')
    parser.add_argument('--standalone', type=pathlib.Path, default=ROOT / 'database/du_lieu_mau.sql')
    parser.add_argument('--setup', type=pathlib.Path, default=ROOT / 'database/app_setup.sql')
    parser.add_argument('--queries', type=pathlib.Path, default=ROOT / 'database/truy_van.sql')
    parser.add_argument('--seed-source', type=pathlib.Path, default=ROOT / 'du_lieu_mau.sql')
    parser.add_argument('--output', type=pathlib.Path, default=ROOT / 'work/new-schema-review/sql-test-results.json')
    args = parser.parse_args()
    data, args.expected = load_expected(args.seed_source)
    args.expected_counts = {table: item['count'] for table, item in args.expected.items()}
    if not args.run:
        print('Prepared only. No Docker command was executed. Raw sample row count: ' + str(sum(args.expected_counts.values())))
        return 0
    review = NewSchemaReview(args, data)
    error = None
    files = [args.schema, args.standalone, args.setup, args.queries, args.seed_source, pathlib.Path(r'E:\CSDL\tao_bang.sql'), pathlib.Path(r'E:\CSDL\truy_van.sql')]
    hashes = {str(file): hashlib.sha256(file.read_bytes()).hexdigest() for file in files if file.exists()}
    try:
        review.run()
    except Exception as exc:
        error = str(exc)
        print('ERROR: ' + error, file=sys.stderr, flush=True)
    finally:
        try:
            review.harness.close()
        except Exception as exc:
            error = (error + '; ' if error else '') + str(exc)
        review.result('all SQL source files remain unchanged during verification', all(file.exists() and hashlib.sha256(file.read_bytes()).hexdigest() == hashes[str(file)] for file in files if str(file) in hashes))
        report = {'container': review.harness.name, 'database': NEW_DB,
                  'isolation': {'network': 'none', 'ports': [], 'host_mounts': [], 'data': 'disposable tmpfs'},
                  'container_removed': review.harness.metadata.get('container_removed', False),
                  'mysql_version': review.harness.metadata.get('mysql_version'), 'source_sha256': hashes,
                  'sample_snapshots': review.snapshots, 'metadata': review.metadata,
                  'results': review.results, 'error': error}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print('Aggregate result: ' + str(args.output), flush=True)
    return int(bool(error) or any(not item['passed'] for item in review.results))


if __name__ == '__main__':
    raise SystemExit(main())
