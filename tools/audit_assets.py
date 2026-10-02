#!/usr/bin/env python3
"""Report referenced PNG storage and decoded pixel budgets, not peak RAM."""
import json
import re
from pathlib import Path
from PIL import Image
from sync_project_files import alpha_only

ROOT = Path(__file__).resolve().parents[1]
paths = set()
for qml in (ROOT / 'qml').rglob('*.qml'):
    paths.update(re.findall(r'"qrc:/([^\"]+\.png)"', qml.read_text()))
rows = []
for path in sorted(paths):
    with Image.open(ROOT / path) as image:
        width, height = image.size
    bpp = 1 if alpha_only(path) else 4
    rows.append(dict(path=path, width=width, height=height,
                     png_bytes=(ROOT / path).stat().st_size,
                     decoded_bytes=width * height * bpp))
print(json.dumps(dict(png_bytes=sum(r['png_bytes'] for r in rows),
                      decoded_bytes=sum(r['decoded_bytes'] for r in rows),
                      assets=sorted(rows, key=lambda r: r['decoded_bytes'], reverse=True)), indent=2))
