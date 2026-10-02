#!/usr/bin/env python3
"""Trim transparent borders while preserving ShellFrame's pixel placement.
Run after generate_cluster_art.py. Original artwork remains the source.
"""
from pathlib import Path
import re
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
qml = ROOT / 'qml/components/ShellFrame.qml'
text = qml.read_text()
out = ROOT / 'assets/cluster/trimmed'
out.mkdir(exist_ok=True)
saved = 0

def trim(match):
    global saved
    name = match.group(1)
    with Image.open(ROOT / 'assets/cluster' / name) as source:
        image = source.convert('RGBA')
        box = image.getchannel('A').getbbox()
        if box is None:
            raise ValueError(f'Empty shell layer: {name}')
        image.crop(box).save(out / name, optimize=True)
        saved += image.width * image.height - (box[2]-box[0]) * (box[3]-box[1])
    return f'        x: {box[0]}; y: {box[1]}\n        source: "qrc:/assets/cluster/trimmed/{name}"'

text = re.sub(r'(?:        x: \d+; y: \d+\n)?        source: "qrc:/assets/cluster/(?:trimmed/)?([^/\"]+\.png)"', trim, text)
qml.write_text(text)
print(f'Alpha8 decoded bytes removed: {saved:,}')
