"""Run SQL checks only in an owned, disposable MySQL container.

No host ports, repository mounts, existing volumes, or application containers are used.
The caller must explicitly pass --run after the SQL files are ready for verification.
"""
from __future__ import annotations

import argparse
import datetime as dt
import hashlib
import json
import pathlib
import re
import secrets
import subprocess
import sys
import time
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[1]
DB = 'quan_ly_dang_ky_khai_tu'
OLD_ROOT = ROOT / 'work' / 'sql-before-report'
LABEL = 'codex.khai-tu-sql-review'
FIXTURE = ROOT / 'tests' / 'sql-fixtures' / 'baseline.sql'


def quote(value):
    if value is None:
        return 'NULL'
    return "'" + str(value).replace('\\', '\\\\').replace("'", "''") + "'"


def person(identity, gender='Nam', birth='1980-01-01', state=None):
    columns = 'CCCD,HoTen,NgaySinh,GioiTinh,QueQuan'
    values = [identity, 'Nguoi thu nghiem', birth, gender, 'Dia ban thu nghiem']
    if state is not None:
        columns += ',TrangThai'
        values.append(state)
    return f"INSERT INTO Cong_Dan ({columns}) VALUES ({','.join(map(quote, values))});\n"


def certificate(identifier='GBT-T', issued='2026-08-02', death='2026-08-01 12:00:00', cause='NN-A', ward='XA-A', hospital='CS-A', place='Noi thu nghiem'):
    values = [identifier, issued, death, place, None, cause, ward, hospital]
    return 'INSERT INTO Giay_Bao_Tu (SoGiayBaoTu,NgayCap,NgayGioMat,NoiMatChiTiet,MoTaNguyenNhan,MaNguyenNhan,MaXaPhuong,MaCSYT) VALUES (' + ','.join(map(quote, values)) + ');\n'


def registration(identifier='KT-T', cert='GBT-T', deceased='990000000001', applicant='990000000002', day='2026-08-03', status='Đã duyệt'):
    values = [identifier, day, 'Con', status, cert, deceased, applicant, 'CB-A']
    return 'INSERT INTO Ho_So_Khai_Tu (SoGiayKhaiTu,NgayDangKi,QuanHe,TrangThaiHoSo,SoGiayBaoTu,CCCD_NgMat,CCCD_NgKhaiTu,MaCanBoTiepNhan) VALUES (' + ','.join(map(quote, values)) + ');\n'


def graph(status='Đã duyệt'):
    return person('990000000001') + person('990000000002') + certificate() + registration(status=status)


class Harness:
    def __init__(self, args):
        self.args = args
        self.name = 'khai-tu-sql-review-20261109-' + uuid.uuid4().hex[:10]
        self.label_value = uuid.uuid4().hex
        self.password = secrets.token_urlsafe(24)
        self.created = False
        self.results = []
        self.metadata = {}

    def docker(self, *args, data=None, timeout=120):
        return subprocess.run(['docker', *args], input=data, capture_output=True, timeout=timeout)

    def owned(self):
        result = self.docker('inspect', '--format', '{{ index .Config.Labels "' + LABEL + '" }}', self.name)
        if result.returncode or result.stdout.decode().strip() != self.label_value:
            raise RuntimeError('Container ownership check failed; refusing to execute or remove it.')

    def start(self):
        result = self.docker('image', 'inspect', self.args.image)
        if result.returncode:
            raise RuntimeError('Image inspection failed; no pull was attempted. Docker stderr: ' + result.stderr.decode(errors='replace')[-1800:])
        result = self.docker('run', '--detach', '--pull=never', '--name', self.name,
                             '--label', LABEL + '=' + self.label_value, '--network', 'none',
                             '--tmpfs', '/var/lib/mysql:rw,nosuid,size=768m',
                             '-e', 'MYSQL_ROOT_PASSWORD=' + self.password,
                             self.args.image, timeout=60)
        if result.returncode:
            raise RuntimeError(result.stderr.decode(errors='replace')[-1500:])
        self.created = True
        self.owned()
        for _ in range(90):
            result = self.docker('exec', '-e', 'MYSQL_PWD=' + self.password, self.name,
                                 'mysqladmin', '-h127.0.0.1', '-uroot', 'ping', '--silent', timeout=15)
            if result.returncode == 0:
                version = self.docker('exec', '-e', 'MYSQL_PWD=' + self.password, self.name,
                                      'mysql', '-h127.0.0.1', '-uroot', '-N', '-B', '-e', 'SELECT VERSION();')
                if version.returncode == 0:
                    self.metadata['mysql_version'] = version.stdout.decode().strip()
                    return
            time.sleep(2)
        raise RuntimeError('Disposable MySQL did not become ready within 180 seconds.')

    def sql(self, text, use_database=True):
        self.owned()
        command = ['exec', '-i', '-e', 'MYSQL_PWD=' + self.password, self.name,
                   'mysql', '-uroot', '--default-character-set=utf8mb4', '--batch', '--raw', '--skip-column-names']
        if use_database:
            command.append(DB)
        return self.docker(*command, data=text.encode('utf-8'))

    def record(self, phase, name, result, expect_error=False, codes=(), expected=None):
        stderr = result.stderr.decode('utf-8', errors='replace')
        errors = [int(value) for value in re.findall(r'ERROR\s+(\d+)', stderr)]
        output = result.stdout.decode('utf-8', errors='replace').strip()
        passed = result.returncode != 0 if expect_error else result.returncode == 0
        if expect_error and codes:
            passed = passed and any(code in errors for code in codes)
        if expected is not None:
            passed = passed and output == expected
        item = {'phase': phase, 'name': name, 'passed': passed, 'returncode': result.returncode, 'error_codes': errors}
        if not passed:
            item['stderr'] = stderr[-1800:]
            item['actual'] = output[-1800:]
            item['expected'] = expected
        self.results.append(item)
        print(('PASS ' if passed else 'FAIL ') + phase + ': ' + name, flush=True)
        return passed

    def apply(self, phase, name, file):
        result = self.sql(pathlib.Path(file).read_text(encoding='utf-8-sig'))
        if not self.record(phase, name, result):
            raise RuntimeError('Schema application failed; see the saved test result.')

    def reset(self):
        result = self.sql(f'DROP DATABASE IF EXISTS {DB}; CREATE DATABASE {DB} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;', use_database=False)
        if result.returncode:
            raise RuntimeError('Could not initialize the isolated test database.')

    def case(self, phase, name, sql, error=False, codes=(), expected=None):
        prefix = "SET SESSION sql_mode='STRICT_TRANS_TABLES,NO_ZERO_DATE,NO_ZERO_IN_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION'; SET time_zone='+07:00'; SET timestamp=UNIX_TIMESTAMP('2026-11-09 12:00:00'); START TRANSACTION;\n"
        return self.record(phase, name, self.sql(prefix + sql + '\nROLLBACK;'), error, codes, expected)

    def checks(self, phase):
        self.apply(phase, 'synthetic lookup fixtures', FIXTURE)
        self.case(phase, 'nullable phone and default ethnicity/living state', person('990000000001') + "SELECT DanToc, SDT IS NULL, TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Kinh\t1\tCòn sống')
        self.case(phase, 'accepted registration marks citizen deceased', graph() + "SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Đã mất')
        self.case(phase, 'rejected registration leaves citizen living', graph('Từ chối') + "SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Còn sống')
        self.case(phase, 'approval on UPDATE marks citizen deceased', graph('Từ chối') + "UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Đã duyệt' WHERE SoGiayKhaiTu='KT-T'; SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Đã mất')
        self.case(phase, 'rejection does not automatically resurrect a citizen', graph() + "UPDATE Ho_So_Khai_Tu SET TrangThaiHoSo='Từ chối' WHERE SoGiayKhaiTu='KT-T'; SELECT TrangThai FROM Cong_Dan WHERE CCCD='990000000001';", expected='Đã mất')
        self.case(phase, 'applicant differs from deceased', person('990000000001') + certificate() + registration(applicant='990000000001'), True, (3819, 1644))
        self.case(phase, 'death cannot follow certificate issue on INSERT', certificate(issued='2026-07-31'), True, (3819, 1644))
        self.case(phase, 'death cannot follow certificate issue on UPDATE', certificate() + "UPDATE Giay_Bao_Tu SET NgayGioMat='2026-08-03 12:00:00' WHERE SoGiayBaoTu='GBT-T';", True, (3819, 1644))
        self.case(phase, 'registration cannot precede certificate issue on INSERT', person('990000000001') + person('990000000002') + certificate() + registration(day='2026-08-01'), True, (1644,))
        self.case(phase, 'registration cannot precede certificate issue on UPDATE', graph() + "UPDATE Ho_So_Khai_Tu SET NgayDangKi='2026-08-01' WHERE SoGiayKhaiTu='KT-T';", True, (1644,))
        self.case(phase, 'parent certificate issue cannot pass existing registration', graph() + "UPDATE Giay_Bao_Tu SET NgayCap='2026-08-04' WHERE SoGiayBaoTu='GBT-T';", True, (1644,))
        self.case(phase, 'one registration per deceased', graph() + certificate('GBT-SECOND') + registration('KT-SECOND', 'GBT-SECOND'), True, (1062,))
        self.case(phase, 'one registration per death notice', graph() + person('990000000003') + registration('KT-SECOND', deceased='990000000003'), True, (1062,))
        burial = "INSERT INTO An_Tang (MaAnTang,HinhThuc,TenNghiaTrang,NgayAnTang,SoGiayKhaiTu) VALUES ('AT-T','Hỏa táng','Nghia trang thu','2026-08-04','KT-T');"
        self.case(phase, 'existing burial columns remain compatible', graph() + burial)
        self.case(phase, 'one burial per registration', graph() + burial + burial.replace("'AT-T'", "'AT-SECOND'"), True, (1062,))
        self.case(phase, 'officer identity is unique', "INSERT INTO Can_Bo (MaCanBo,CCCD,HoTen,ChucVu,MaUBND) VALUES ('CB-SECOND','990000000901','Can bo thu','Ho tich','UB-A');", True, (1062,))
        for identity in ['99000000000X', '99000000001', '９９０００００００００１']:
            self.case(phase, 'citizen identity rejects ' + ('non-ASCII' if not identity.isascii() else 'non-digit/short'), person(identity), True, (3819, 1644))
        self.case(phase, 'citizen identity rejects 13 characters', person('9900000000001'), True, (1406,))
        self.case(phase, 'gender rejects values outside the enum', person('990000000001', gender='Invalid'), True, (1265, 3819, 1644))
        self.case(phase, 'citizen state rejects unsupported values', person('990000000001', state='Đang sống'), True, (3819, 1644))
        self.case(phase, 'registration state rejects unsupported values', graph('Đã hoàn tất'), True, (3819, 1644))
        self.case(phase, 'lookup identifier length 20 is accepted', "INSERT INTO Noi_Mat VALUES ('" + 'W' * 20 + "','Xa thu');")
        self.case(phase, 'lookup identifier length 21 is rejected', "INSERT INTO Noi_Mat VALUES ('" + 'W' * 21 + "','Xa thu');", True, (1406,))
        self.case(phase, 'phone length 16 is rejected', person('990000000001') + "UPDATE Cong_Dan SET SDT='0000000000000000' WHERE CCCD='990000000001';", True, (1406,))
        self.case(phase, 'long nullable description uses TEXT', certificate() + "UPDATE Giay_Bao_Tu SET MoTaNguyenNhan=REPEAT('x',2000),NoiMatChiTiet=REPEAT('x',255) WHERE SoGiayBaoTu='GBT-T';")
        self.case(phase, 'death place length 256 is rejected', certificate() + "UPDATE Giay_Bao_Tu SET NoiMatChiTiet=REPEAT('x',256) WHERE SoGiayBaoTu='GBT-T';", True, (1406,))
        self.case(phase, 'foreign keys reject unknown lookup values', certificate(cause='MISSING'), True, (1452,))
        metadata = self.sql("SELECT EVENT_OBJECT_TABLE,TRIGGER_NAME,ACTION_TIMING,EVENT_MANIPULATION FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE() ORDER BY TRIGGER_NAME; SELECT TABLE_NAME,COLUMN_NAME,COLUMN_TYPE,IS_NULLABLE,COALESCE(COLUMN_DEFAULT,'<NULL>') FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() ORDER BY TABLE_NAME,ORDINAL_POSITION;")
        self.metadata[phase] = metadata.stdout.decode('utf-8', errors='replace').splitlines()
        self.record(phase, 'metadata inspection', metadata)

    def query_smoke(self, phase='fresh'):
        if not self.args.queries or not self.args.queries.exists():
            self.metadata['report_queries'] = 'No query file was provided; not executed.'
            return
        text = self.args.queries.read_text(encoding='utf-8-sig')
        self.case(phase, 'report query file executes on the real schema', text)

    def dirty_preflight(self):
        for label, rows in [
            ('invalid legacy citizen identity', "INSERT INTO Cong_Dan VALUES ('1','Nguoi thu','1980-01-01','Nam','Noi thu','Kinh','000','Đang sống');"),
            ('overlong legacy lookup identifier', "INSERT INTO Noi_Mat VALUES ('WWWWWWWWWWWWWWWWWWWWW','Xa thu');")
        ]:
            self.reset()
            self.apply('dirty-preflight', label + ': original base DDL', self.args.old_schema)
            self.apply('dirty-preflight', label + ': original account setup', self.args.old_setup)
            seed = rows + " CREATE TRIGGER KT_Update_HoSo_AI AFTER INSERT ON Ho_So_Khai_Tu FOR EACH ROW SET @kt_test_trigger=1;"
            if self.sql(seed).returncode:
                raise RuntimeError('Could not seed the synthetic dirty preflight case.')
            self.record('dirty-preflight', label + ': migration rejects data', self.sql(self.args.migration.read_text(encoding='utf-8-sig')), True, (1644,))
            state = self.sql("SELECT CHARACTER_MAXIMUM_LENGTH,(SELECT COUNT(*) FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE()) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='Cong_Dan' AND COLUMN_NAME='CCCD';")
            self.record('dirty-preflight', label + ': old column and trigger unchanged', state, expected='100\t1')

    def nonempty_upgrade(self):
        self.reset()
        self.apply('nonempty-upgrade', 'original base DDL', self.args.old_schema)
        self.apply('nonempty-upgrade', 'original account setup', self.args.old_setup)
        self.apply('nonempty-upgrade', 'synthetic existing records', ROOT / 'tests/sql-fixtures/legacy.sql')
        self.apply('nonempty-upgrade', 'upgrade populated schema', self.args.migration)
        self.record('nonempty-upgrade', 'all existing row counts preserved', self.sql('SELECT (SELECT COUNT(*) FROM Cong_Dan),(SELECT COUNT(*) FROM Giay_Bao_Tu),(SELECT COUNT(*) FROM Ho_So_Khai_Tu),(SELECT COUNT(*) FROM An_Tang);'), expected='5\t4\t4\t1')
        self.record('nonempty-upgrade', 'known registration labels normalized', self.sql('SELECT SoGiayKhaiTu,TrangThaiHoSo FROM Ho_So_Khai_Tu ORDER BY SoGiayKhaiTu;'), expected='KT-LEG-1\tĐã duyệt\nKT-LEG-2\tChờ xử lý\nKT-LEG-3\tChờ xử lý\nKT-LEG-4\tTừ chối')
        self.record('nonempty-upgrade', 'known living labels normalized without backfilling deceased', self.sql('SELECT CCCD,TrangThai FROM Cong_Dan ORDER BY CCCD;'), expected='990000000101\tĐã mất\n990000000102\tCòn sống\n990000000103\tCòn sống\n990000000104\tCòn sống\n990000000105\tCòn sống')
        self.record('nonempty-upgrade', 'existing burial fields and date preserved', self.sql("SELECT MaAnTang,HinhThuc,TenNghiaTrang,NgayAnTang,SoGiayKhaiTu FROM An_Tang;"), expected='AT-LEG\tHỏa táng\tNghia trang giu nguyen\t2026-08-04\tKT-LEG-1')
        self.apply('nonempty-upgrade', 'populated migration can be rerun', self.args.migration)

    def compare_fresh_metadata(self):
        source = ROOT / 'work/pdf-review/sql-test-fresh-final.json'
        if not source.exists():
            return
        fresh = json.loads(source.read_text(encoding='utf-8'))['metadata']['fresh']
        expected = {line for line in fresh if len(line.split('\t')) == 5}
        actual = {line for line in self.metadata['upgrade'] if len(line.split('\t')) == 5}
        passed = actual == expected
        self.results.append({'phase': 'upgrade', 'name': 'all column types/nullability/defaults match fresh DDL', 'passed': passed, 'missing': sorted(expected-actual), 'unexpected': sorted(actual-expected)})
        print(('PASS ' if passed else 'FAIL ') + 'upgrade: all column types/nullability/defaults match fresh DDL', flush=True)

    def run(self):
        self.start()
        if self.args.phase in ('fresh', 'all'):
            self.reset()
            self.apply('fresh', 'new base DDL', self.args.schema)
            self.apply('fresh', 'application account setup after new DDL', self.args.setup)
            self.checks('fresh')
            self.query_smoke()
        if self.args.phase == 'fresh':
            return
        self.reset()
        self.apply('upgrade', 'original base DDL', self.args.old_schema)
        self.apply('upgrade', 'original account setup', self.args.old_setup)
        self.apply('upgrade', 'upgrade existing schema', self.args.migration)
        self.checks('upgrade')
        self.compare_fresh_metadata()
        self.query_smoke('upgrade')
        self.apply('upgrade', 'upgrade can be rerun', self.args.migration)
        self.nonempty_upgrade()
        self.dirty_preflight()

    def close(self):
        if self.created:
            self.owned()
            result = self.docker('rm', '--force', self.name, timeout=60)
            if result.returncode:
                raise RuntimeError('Could not remove the owned disposable test container.')
            self.metadata['container_removed'] = True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--run', action='store_true', help='Actually run the isolated test container.')
    parser.add_argument('--image', default='mysql:8.0')
    parser.add_argument('--phase', choices=['fresh', 'upgrade', 'all'], default='all')
    parser.add_argument('--schema', type=pathlib.Path, default=ROOT / 'database/he_thong_quan_ly_dang_ky_khai_tu.sql')
    parser.add_argument('--setup', type=pathlib.Path, default=ROOT / 'database/app_setup.sql')
    parser.add_argument('--migration', type=pathlib.Path, default=ROOT / 'database/cap_nhat_rang_buoc.sql')
    parser.add_argument('--old-schema', type=pathlib.Path, default=OLD_ROOT / 'he_thong_quan_ly_dang_ky_khai_tu.sql')
    parser.add_argument('--old-setup', type=pathlib.Path, default=OLD_ROOT / 'app_setup.sql')
    parser.add_argument('--queries', type=pathlib.Path, default=ROOT / 'database/truy_van_bao_cao.sql')
    parser.add_argument('--output', type=pathlib.Path, default=ROOT / 'work/pdf-review' / ('sql-test-results-' + dt.datetime.now().strftime('%Y%m%d-%H%M%S') + '.json'))
    args = parser.parse_args()
    if not args.run:
        print('Prepared only. Pass --run after the SQL files are ready. No Docker command was executed.')
        return 0
    harness = Harness(args)
    error = None
    try:
        harness.run()
    except Exception as exc:
        error = str(exc)
        print('HARNESS ERROR: ' + error, file=sys.stderr, flush=True)
    finally:
        try:
            harness.close()
        except Exception as exc:
            error = (error + '; ' if error else '') + str(exc)
        source_hashes = {str(file): hashlib.sha256(file.read_bytes()).hexdigest() for file in [args.schema, args.setup, args.old_schema, args.old_setup, args.migration, args.queries, FIXTURE, ROOT / 'tests/sql-fixtures/legacy.sql'] if file and file.exists()}
        report = {'container': harness.name, 'isolation': {'network': 'none', 'ports': [], 'host_mounts': [], 'data': 'disposable tmpfs'}, 'source_sha256': source_hashes, 'results': harness.results, 'metadata': harness.metadata, 'error': error}
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
        print('Result: ' + str(args.output), flush=True)
    return int(bool(error) or any(not item['passed'] for item in harness.results))


if __name__ == '__main__':
    raise SystemExit(main())
