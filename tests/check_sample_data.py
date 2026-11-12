"""Verify seeded DDL in an owned disposable MySQL instance, returning aggregates only.

Use --run only after the seed has been appended to the main DDL. Two fresh imports
are compared to establish deterministic row counts and server-computed checksums.
No individual citizen rows are returned, logged, or written to the result file.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import re
import sys

from sql_report_check import Harness, ROOT

TABLES = ('Nguyen_Nhan', 'CSYT', 'Cong_Dan', 'UBND', 'Noi_Mat', 'Can_Bo',
          'Giay_Bao_Tu', 'Ho_So_Khai_Tu', 'An_Tang')
RELATIONS = (
    ('Can_Bo', 'MaUBND', 'UBND', 'MaUBND'),
    ('Giay_Bao_Tu', 'MaNguyenNhan', 'Nguyen_Nhan', 'MaNguyenNhan'),
    ('Giay_Bao_Tu', 'MaXaPhuong', 'Noi_Mat', 'MaXaPhuong'),
    ('Giay_Bao_Tu', 'MaCSYT', 'CSYT', 'MaCSYT'),
    ('Ho_So_Khai_Tu', 'SoGiayBaoTu', 'Giay_Bao_Tu', 'SoGiayBaoTu'),
    ('Ho_So_Khai_Tu', 'CCCD_NgMat', 'Cong_Dan', 'CCCD'),
    ('Ho_So_Khai_Tu', 'CCCD_NgKhaiTu', 'Cong_Dan', 'CCCD'),
    ('Ho_So_Khai_Tu', 'MaCanBoTiepNhan', 'Can_Bo', 'MaCanBo'),
    ('An_Tang', 'SoGiayKhaiTu', 'Ho_So_Khai_Tu', 'SoGiayKhaiTu'),
)


class SeedReview:
    def __init__(self, args):
        self.args = args
        self.harness = Harness(args)
        self.results = []
        self.snapshots = []
        self.metadata = {}

    def result(self, name, passed, **details):
        self.results.append({'name': name, 'passed': bool(passed), **details})
        print(('PASS ' if passed else 'FAIL ') + name, flush=True)

    def execute(self, sql, name, use_database=True):
        process = self.harness.sql(sql, use_database=use_database)
        if process.returncode:
            # Keep error codes and SQL line numbers without logging rejected row values.
            message = process.stderr.decode('utf-8', errors='replace')
            self.result(name, False, error_codes=re.findall(r'ERROR\s+(\d+)', message),
                        sql_lines=re.findall(r'at line\s+(\d+)', message))
            raise RuntimeError(name + ' failed; see aggregate error metadata.')
        return process.stdout.decode('utf-8', errors='replace').strip()

    def import_fresh(self, number):
        self.harness.reset()
        source = self.args.schema.read_text(encoding='utf-8-sig')
        if number == 3:
            marker = '-- BEGIN DU_LIEU_MAU_2026_11_10'
            if marker not in source:
                raise RuntimeError('Cannot separate DDL from the appended seed marker.')
            self.execute(source.split(marker, 1)[0], 'import 3: DDL without appended seed')
            self.execute(self.args.standalone.read_text(encoding='utf-8-sig'), 'import 3: standalone seed on empty schema')
            self.result('import 3: standalone seed on empty schema', True)
        else:
            self.execute(source, f'import {number}: main DDL and sample rows')
            self.result(f'import {number}: main DDL and sample rows', True)
        self.execute(self.args.setup.read_text(encoding='utf-8-sig'), f'import {number}: account setup')
        self.result(f'import {number}: account setup', True)

    def snapshot(self):
        schema = self.execute("SELECT TABLE_NAME,COLUMN_NAME,COLUMN_KEY FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION;", 'inspect schema metadata')
        columns = {table: [] for table in TABLES}
        primary = {table: [] for table in TABLES}
        for line in schema.splitlines():
            table, column, key = (line.split('\t') + ['', '', ''])[:3]
            if table in columns:
                columns[table].append(column)
                if key == 'PRI':
                    primary[table].append(column)
        rows = {}
        for table in TABLES:
            if not columns[table] or not primary[table]:
                raise RuntimeError('Missing expected table or primary key: ' + table)
            ordered_columns = self.args.expected.get(table, {}).get('columns', columns[table])
            cells = [f"IF(`{column}` IS NULL,'null',JSON_QUOTE(CAST(`{column}` AS CHAR CHARACTER SET utf8mb4)))" for column in ordered_columns]
            row_json = "CONCAT('['," + ",',',".join(cells) + ",']')"
            ordering = ','.join('BINARY `' + column + '`' for column in primary[table])
            # Match Python json.dumps(rows, ensure_ascii=False, separators=(',', ':'))
            # exactly, without retrieving any individual row from the database.
            sql = "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci; SET SESSION group_concat_max_len=16777216; SET time_zone='+07:00'; "
            sql += f"SELECT COUNT(*),SHA2(CONCAT('[',COALESCE(GROUP_CONCAT({row_json} ORDER BY {ordering} SEPARATOR ','),''),']'),256) FROM `{table}`;"
            count, digest = self.execute(sql, 'aggregate checksum for ' + table).split('\t')
            rows[table] = {'rows': int(count), 'sha256': digest}
            if int(count) * 64 > 16777216:
                raise RuntimeError('Checksum buffer would truncate; increase its limit before proceeding.')
        return rows

    def constraints(self):
        for kind, expected in [('FOREIGN KEY', 9), ('CHECK', 6), ('UNIQUE', 4)]:
            count = int(self.execute("SELECT COUNT(*) FROM information_schema.TABLE_CONSTRAINTS WHERE CONSTRAINT_SCHEMA=DATABASE() AND TABLE_NAME<>'App_User' AND CONSTRAINT_TYPE='" + kind + "';", 'constraint count ' + kind))
            self.metadata[kind] = count
            self.result('business constraint count: ' + kind, count == expected, expected=expected, actual=count)
        triggers = int(self.execute('SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE();', 'trigger count'))
        self.metadata['triggers'] = triggers
        self.result('five business triggers are installed', triggers == 5, actual=triggers)
        violations = {}
        for child, column, parent, target in RELATIONS:
            sql = f'SELECT COUNT(*) FROM `{child}` c LEFT JOIN `{parent}` p ON p.`{target}`=c.`{column}` WHERE p.`{target}` IS NULL;'
            violations[child + '.' + column] = int(self.execute(sql, 'foreign key integrity aggregate'))
        rules = {
            'death_before_birth': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Cong_Dan c ON c.CCCD=h.CCCD_NgMat JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE c.NgaySinh>DATE(g.NgayGioMat);',
            'applicant_birth_after_registration': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Cong_Dan c ON c.CCCD=h.CCCD_NgKhaiTu WHERE c.NgaySinh>h.NgayDangKi;',
            'death_after_issue': 'SELECT COUNT(*) FROM Giay_Bao_Tu WHERE DATE(NgayGioMat)>NgayCap;',
            'issue_after_registration': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE g.NgayCap>h.NgayDangKi;',
            'same_applicant_and_deceased': 'SELECT COUNT(*) FROM Ho_So_Khai_Tu WHERE CCCD_NgMat=CCCD_NgKhaiTu;',
            'burial_before_death': 'SELECT COUNT(*) FROM An_Tang a JOIN Ho_So_Khai_Tu h ON h.SoGiayKhaiTu=a.SoGiayKhaiTu JOIN Giay_Bao_Tu g ON g.SoGiayBaoTu=h.SoGiayBaoTu WHERE a.NgayAnTang<DATE(g.NgayGioMat);',
            'accepted_registration_without_deceased_state': "SELECT COUNT(*) FROM Ho_So_Khai_Tu h JOIN Cong_Dan c ON c.CCCD=h.CCCD_NgMat WHERE h.TrangThaiHoSo<>'Từ chối' AND c.TrangThai<>'Đã mất';",
        }
        for key, sql in rules.items():
            violations[key] = int(self.execute(sql, key))
        self.metadata['integrity_violation_counts'] = violations
        self.result('sample relationships and chronology contain no violations', all(value == 0 for value in violations.values()), counts=violations)
        users = int(self.execute('SELECT COUNT(*) FROM App_User;', 'account aggregate'))
        self.result('sample SQL does not create application accounts', users == 0, actual=users)

    def run(self):
        self.harness.start()
        for number in (1, 2, 3):
            self.import_fresh(number)
            snapshot = self.snapshot()
            self.snapshots.append(snapshot)
            for table, expected in self.args.expected_counts.items():
                self.result(f'import {number}: {table} row count', snapshot[table]['rows'] == expected,
                            expected=expected, actual=snapshot[table]['rows'])
                expected_digest = self.args.expected.get(table, {}).get('sha256')
                if expected_digest:
                    self.result(f'import {number}: {table} matches canonical source checksum',
                                snapshot[table]['sha256'] == expected_digest)
            if number == 1:
                self.constraints()
                if self.args.queries.exists():
                    self.execute(self.args.queries.read_text(encoding='utf-8-sig'), 'seven report queries execute on the seeded schema')
                    self.result('seven report queries execute on the seeded schema', True)
        self.result('two fresh imports have identical row counts and checksums', self.snapshots[0] == self.snapshots[1])
        self.result('standalone seed matches the seed embedded in main DDL', self.snapshots[0] == self.snapshots[2])


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true')
    parser.add_argument('--image', default='mysql:8.0')
    parser.add_argument('--schema', type=pathlib.Path, default=ROOT / 'database/he_thong_quan_ly_dang_ky_khai_tu.sql')
    parser.add_argument('--setup', type=pathlib.Path, default=ROOT / 'database/app_setup.sql')
    parser.add_argument('--queries', type=pathlib.Path, default=ROOT / 'database/truy_van_bao_cao.sql')
    parser.add_argument('--seed-source', type=pathlib.Path)
    parser.add_argument('--standalone', type=pathlib.Path, default=ROOT / 'database/du_lieu_mau.sql')
    parser.add_argument('--expected', type=pathlib.Path, default=ROOT / 'work/seed-review/expected-counts.json')
    parser.add_argument('--counts', action='append', default=[], metavar='TABLE=COUNT')
    parser.add_argument('--output', type=pathlib.Path, default=ROOT / 'work/seed-review/sample-data-check.json')
    args = parser.parse_args()
    args.expected = json.loads(args.expected.read_text(encoding='utf-8')) if args.expected.exists() else {}
    args.expected_counts = {table: item['count'] for table, item in args.expected.items()}
    for item in args.counts:
        table, count = item.split('=', 1)
        if table not in TABLES or not count.isdigit():
            parser.error('--counts requires a known business table and a nonnegative integer.')
        args.expected_counts[table] = int(count)
    if not args.run:
        print('Prepared only. No Docker command was executed.')
        return 0
    review = SeedReview(args)
    error = None
    files = [args.schema, args.setup, args.queries, args.seed_source, args.standalone, args.expected]
    source_before = {str(file): hashlib.sha256(file.read_bytes()).hexdigest() for file in files if file and file.exists()}
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
        source_after = {str(file): hashlib.sha256(file.read_bytes()).hexdigest() for file in files if file and file.exists()}
        review.result('SQL sources remain unchanged during verification', source_before == source_after)
        report = {'container': review.harness.name,
                  'isolation': {'network': 'none', 'ports': [], 'host_mounts': [], 'data': 'disposable tmpfs'},
                  'container_removed': review.harness.metadata.get('container_removed', False),
                  'mysql_version': review.harness.metadata.get('mysql_version'),
                  'source_sha256': source_before, 'snapshots': review.snapshots,
                  'metadata': review.metadata, 'results': review.results, 'error': error}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print('Aggregate result: ' + str(args.output), flush=True)
    return int(bool(error) or any(not result['passed'] for result in review.results))


if __name__ == '__main__':
    raise SystemExit(main())
