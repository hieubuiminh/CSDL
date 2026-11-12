from pathlib import Path
from pypdf import PdfReader
import json

source = Path(r'C:\Users\ADMIN\Downloads\bao-cao-updated_removed.pdf')
target = Path(r'E:\CSDL\he_thong_quan_ly_dang_ky_khai_tu\work\pdf-review')
reader = PdfReader(source)
pages = []
for index, page in enumerate(reader.pages, 1):
    content = page.extract_text(extraction_mode='layout') or ''
    (target / f'page-{index:02}.txt').write_text(content, encoding='utf-8')
    pages.append({'pdfPage': index, 'text': content})
(target / 'pages.json').write_text(json.dumps(pages, ensure_ascii=False, indent=2), encoding='utf-8')
(target / 'report.txt').write_text('\n\n'.join(f'===== PDF PAGE {page["pdfPage"]} =====\n{page["text"]}' for page in pages), encoding='utf-8')
print(json.dumps({'pages': len(pages), 'characters': sum(len(page['text']) for page in pages)}))
