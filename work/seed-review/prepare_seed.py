"""Adapt the supplied INSERT-only sample to the project's existing schema."""
from __future__ import annotations

import hashlib
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
MARKER = '-- BEGIN DU_LIEU_MAU_2026_11_10'
TABLES = ['Nguyen_Nhan', 'CSYT', 'Noi_Mat', 'UBND', 'Can_Bo',
          'Cong_Dan', 'Giay_Bao_Tu', 'Ho_So_Khai_Tu', 'An_Tang']


def parse_inserts(source):
    position = 0
    result = {}

    def skip():
        nonlocal position
        while position < len(source):
            if source[position].isspace() or source[position] == '\ufeff':
                position += 1
            elif source.startswith('--', position):
                end = source.find('\n', position)
                position = len(source) if end == -1 else end + 1
            else:
                break

    def literal():
        nonlocal position
        skip()
        if source[position] == "'":
            position += 1
            value = ''
            while position < len(source):
                char = source[position]
                position += 1
                if char == "'":
                    if position < len(source) and source[position] == "'":
                        position += 1
                        value += "'"
                    else:
                        return value
                elif char == '\\':
                    escaped = source[position]
                    position += 1
                    value += {'n': '\n', 'r': '\r', 't': '\t', '0': '\0', 'b': '\b', 'Z': '\x1a'}.get(escaped, escaped)
                else:
                    value += char
            raise ValueError('Unterminated SQL string')
        match = re.match(r'NULL\b|[-+]?\d+', source[position:], re.I)
        if not match:
            raise ValueError('Only scalar INSERT literals are supported')
        position += len(match.group())
        return None if match.group().upper() == 'NULL' else int(match.group())

    while True:
        skip()
        if position == len(source):
            break
        match = re.match(r'INSERT\s+INTO\s+(\w+)\s*\(([^)]+)\)\s*VALUES\s*', source[position:], re.I)
        if not match:
            raise ValueError('Unexpected statement; the sample must contain INSERTs only')
        table, columns_text = match.groups()
        if table not in TABLES or table in result:
            raise ValueError('Unexpected or repeated sample table')
        columns = [column.strip() for column in columns_text.split(',')]
        if len(set(columns)) != len(columns):
            raise ValueError('Duplicate column')
        position += len(match.group())
        rows = []
        while True:
            skip()
            if source[position] != '(':
                raise ValueError('Expected tuple')
            position += 1
            row = []
            while True:
                row.append(literal())
                skip()
                if source[position] == ')':
                    position += 1
                    break
                if source[position] != ',':
                    raise ValueError('Expected value separator')
                position += 1
            if len(row) != len(columns):
                raise ValueError('Tuple width differs from INSERT column count')
            rows.append(dict(zip(columns, row)))
            skip()
            if source[position] == ';':
                position += 1
                break
            if source[position] != ',':
                raise ValueError('Expected tuple separator')
            position += 1
        result[table] = {'columns': columns, 'rows': rows}
    if set(result) != set(TABLES):
        raise ValueError('The sample must contain all nine core tables')
    return result


def canonical_data():
    data = parse_inserts((ROOT / 'du_lieu_mau.sql').read_text(encoding='utf-8-sig'))
    certificates = data['Giay_Bao_Tu']
    deceased_by_certificate = {row['SoGiayBaoTu']: row['CCCD_NgMat'] for row in certificates['rows']}
    if len(deceased_by_certificate) != len(certificates['rows']):
        raise ValueError('Duplicate certificate identifier')
    for row in data['Ho_So_Khai_Tu']['rows']:
        row['CCCD_NgMat'] = deceased_by_certificate[row['SoGiayBaoTu']]
    columns = data['Ho_So_Khai_Tu']['columns']
    columns.insert(columns.index('SoGiayBaoTu') + 1, 'CCCD_NgMat')
    certificates['columns'].remove('CCCD_NgMat')
    for row in certificates['rows']:
        del row['CCCD_NgMat']
    return data


def quote(value):
    if value is None:
        return 'NULL'
    if isinstance(value, int):
        return str(value)
    return "'" + value.replace('\\', '\\\\').replace("'", "''").replace('\n', '\\n').replace('\r', '\\r').replace('\0', '\\0') + "'"


def write_outputs():
    data = canonical_data()
    sections = [
        '-- DỮ LIỆU MẪU GIẢ: chuyển từ du_lieu_mau.sql do chủ dự án cung cấp.',
        '-- Giữ dữ liệu gốc; chuyển CCCD người mất về Ho_So_Khai_Tu theo schema hiện tại.',
        '-- Nạp một lần sau schema; không chạy lặp nếu đã có các mã mẫu này.',
        '-- Không dùng INSERT IGNORE/REPLACE, không xóa hoặc ghi đè dữ liệu đang có.',
        'SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci;',
        'USE quan_ly_dang_ky_khai_tu;',
        'START TRANSACTION;',
    ]
    summary = {}
    for table in TABLES:
        columns, rows = data[table]['columns'], data[table]['rows']
        sections.append('\n-- ' + str(len(rows)) + ' bản ghi ' + table)
        sections.append('INSERT INTO ' + table + ' (' + ','.join(columns) + ') VALUES')
        sections.append(',\n'.join('  (' + ','.join(quote(row[column]) for column in columns) + ')' for row in rows) + ';')
        ordered = sorted(([row[column] for column in columns] for row in rows), key=lambda row: row[0])
        payload = json.dumps(ordered, ensure_ascii=False, separators=(',', ':')).encode('utf-8')
        summary[table] = {'count': len(rows), 'columns': columns, 'sha256': hashlib.sha256(payload).hexdigest()}
    sections.extend(['\nCOMMIT;', ''])
    seed = '\n'.join(sections)
    (ROOT / 'database/du_lieu_mau.sql').write_text(seed, encoding='utf-8')
    schema_path = ROOT / 'database/he_thong_quan_ly_dang_ky_khai_tu.sql'
    schema = schema_path.read_text(encoding='utf-8-sig').split(MARKER, 1)[0].rstrip()
    header = '-- File này đã bao gồm dữ liệu mẫu; không nạp lại database/du_lieu_mau.sql sau đó.'
    if header not in schema:
        first, rest = schema.split('\n', 1)
        schema = first + '\n' + header + '\n' + rest
    schema_path.write_text(schema + '\n\n' + MARKER + '\n' + seed + '-- END DU_LIEU_MAU_2026_11_10\n', encoding='utf-8')
    (ROOT / 'work/seed-review/expected-counts.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(json.dumps({'counts': {table: value['count'] for table, value in summary.items()}, 'total': sum(value['count'] for value in summary.values())}, ensure_ascii=False))


if __name__ == '__main__':
    write_outputs()
