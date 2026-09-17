#!/usr/bin/env python3
"""Fails when the screens ask for a font face that is not shipped.

Qt for MCUs does not synthesise a style it does not have: a Text with
font.italic set, in a weight whose italic face is missing, quietly renders
upright. Nineteen blocks were doing exactly that. Every upright face in
assets/fonts must therefore have an italic partner, and every weight the QML
asks for must be a face that exists.

    python3 tools/font_check.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, "assets", "fonts")

# Qt's weight names, and the face each one needs.
WEIGHTS = {"Font.Normal": "Regular", "Font.DemiBold": "SemiBold", "Font.Bold": "Bold"}
WEIGHT_RE = re.compile(r"font\.weight:\s*(Font\.\w+)")


def faces():
    return {name[:-4] for name in os.listdir(FONTS) if name.endswith(".ttf")}


def problems(qml_root):
    have = faces()
    found = []

    for face in sorted(have):
        if face.endswith("Italic"):
            continue
        # The roman face is named Regular but its italic drops the word, the
        # way the family itself names them.
        partner = face[:-len("Regular")] + "Italic" if face.endswith("Regular") else face + "Italic"
        if partner not in have:
            found.append("%s.ttf has no italic partner (%s.ttf)" % (face, partner))

    family = os.path.basename(sorted(have)[0]).split("-")[0] if have else ""
    asked = set()
    for base, _, files in os.walk(qml_root):
        for name in sorted(files):
            if name.endswith(".qml"):
                for match in WEIGHT_RE.finditer(open(os.path.join(base, name)).read()):
                    asked.add(match.group(1))

    for weight in sorted(asked):
        if weight not in WEIGHTS:
            found.append("QML asks for %s, which maps to no face here" % weight)
            continue
        face = "%s-%s" % (family, WEIGHTS[weight])
        if face not in have:
            found.append("QML asks for %s but %s.ttf is missing" % (weight, face))

    return found


if __name__ == "__main__":
    hits = problems(sys.argv[1] if len(sys.argv) > 1 else os.path.join(ROOT, "qml"))
    for line in hits:
        print(line)
    print("font_check: %d problem(s)" % len(hits))
    sys.exit(1 if hits else 0)
