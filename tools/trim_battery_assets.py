#!/usr/bin/env python3
"""Crop full-canvas battery masks, preserving their QML coordinates.
Run after generate_cluster_art.py and before sync_project_files.py.
"""
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
TARGETS = {
    'qml/components/BatteryColumn.qml': ['battery_tall.png'],
    'qml/screens/HexSpeedoView.qml': ['battery_edge_inner.png', 'battery_edge_outer.png', 'battery_tall_gloss.png'],
}
saved = 0
for filename, names in TARGETS.items():
    path = ROOT / filename
    text = path.read_text()
    for name in names:
        with Image.open(ROOT / 'assets/cluster' / name) as source:
            image = source.convert('RGBA')
            box = image.getchannel('A').getbbox()
            if not box or image.size != (1280, 480):
                raise ValueError(f'Expected a nonempty full-canvas mask: {name}')
            target = ROOT / 'assets/cluster/trimmed' / name
            target.parent.mkdir(exist_ok=True)
            image.crop(box).save(target, optimize=True)
            saved += image.width * image.height - (box[2]-box[0]) * (box[3]-box[1])
        pattern = r'(?:        x: \d+; y: \d+\n)?        source: "qrc:/assets/cluster/(?:trimmed/)?' + re.escape(name) + '"'
        text, count = re.subn(pattern, f'        x: {box[0]}; y: {box[1]}\n        source: "qrc:/assets/cluster/trimmed/{name}"', text)
        if count != 1:
            raise ValueError(f'Expected one unscaled reference for {name}, got {count}')
    path.write_text(text)
print(f'Alpha8 decoded bytes removed: {saved:,}')
