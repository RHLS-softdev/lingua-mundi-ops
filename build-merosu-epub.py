#!/usr/bin/env python3
"""Builds a demo EPUB from an Aozora Bunko text file (Shift_JIS) as CLEAN
plain Japanese text — deliberately WITHOUT furigana/ruby, so the Shikibu
demonstration can add it live with Auto Ruby.

- Decodes Shift_JIS
- Drops Aozora's bibliographic header (up to the ---- separator)
- Strips Aozora ruby markup ｜漢字《かんじ》 down to the base text 漢字
  (no readings — the whole point is that Shikibu adds them)
- Strips ［＃...］ editorial annotations
- Packages a minimal valid EPUB3 (mimetype / container.xml / content.opf /
  single chapter XHTML), one paragraph per line.
"""
import re
import zipfile
from pathlib import Path

SRC = Path("/home/rex/Documentos/Software Development/DeepSeek Harness/.aozora/hashire_merosu.txt")
OUT = Path("/home/rex/Documentos/Software Development/DeepSeek Harness/走れメロス.epub")

text = SRC.read_bytes().decode("shift_jis")

marker = "-------------------------------------------------------"
# Aozora files have the separator twice: once before the symbol-key
# block (【テキスト中に現れる記号について】), once before the story.
# Cut after the LAST separator so only the story text remains.
positions = [m.start() for m in re.finditer(re.escape(marker), text)]
idx = positions[-1] if positions else text.find(marker)
body = text[idx + len(marker):] if idx != -1 else text

for end_marker in ("底本：", "入力：", "校正："):
    e = body.find(end_marker)
    if e != -1:
        body = body[:e]
        break

body = re.sub(r"［＃.*?］", "", body, flags=re.S)
# Strip ruby markup to base text only (no readings).
body = re.sub(r"｜([^《\n]{1,20})《[^》\n]{1,30}》", r"\1", body)
body = re.sub(r"([\u4e00-\u9fff\u3400-\u4dbf]{1,12})《[^》\n]{1,30}》", r"\1", body)

paragraphs = [ln.strip() for ln in body.splitlines() if ln.strip()]

def esc(s):
    return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;")

para_html = "".join(f"<p>{esc(p)}</p>" for p in paragraphs)

chapter = f"""<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja" lang="ja">
<head>
<meta charset="utf-8" />
<title>走れメロス</title>
</head>
<body>
<h1>走れメロス</h1>
<p class="author">太宰治</p>
{para_html}
</body>
</html>
"""

opf = """<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="uid">aozora-1567-merosu</dc:identifier>
    <dc:title>走れメロス</dc:title>
    <dc:creator>太宰治</dc:creator>
    <dc:language>ja</dc:language>
    <meta property="dcterms:modified">2026-08-25T00:00:00Z</meta>
  </metadata>
  <manifest>
    <item id="ch1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="ch1"/>
  </spine>
</package>
"""

container = """<?xml version="1.0" encoding="utf-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>
"""

with zipfile.ZipFile(OUT, "w", zipfile.ZIP_DEFLATED) as z:
    z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
    z.writestr("META-INF/container.xml", container)
    z.writestr("OEBPS/content.opf", opf)
    z.writestr("OEBPS/chapter1.xhtml", chapter)

print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")
print(f"paragraphs: {len(paragraphs)}, ruby elements: {chapter.count('<ruby>')} (must be 0)")
