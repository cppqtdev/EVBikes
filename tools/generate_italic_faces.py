#!/usr/bin/env python3
"""Builds the italic faces the UI asks for but the family does not ship.

assets/fonts holds Inter Regular, SemiBold, Bold and Bold Italic. The screens
set font.italic on plenty of text that is neither bold nor italic-capable, so on
the board those lines come out upright: Qt for MCUs picks the nearest face it
has, and a missing style is silently the roman one.

Rather than change the design, the two missing faces are drawn here by slanting
the roman outlines at the family's own italic angle (Inter Bold Italic reports
-9.4 degrees), which is what an oblique face is. Run after changing the fonts:

    python3 tools/generate_italic_faces.py
"""
import math
import os

from fontTools.misc.transform import Transform
from fontTools.pens.recordingPen import DecomposingRecordingPen
from fontTools.pens.transformPen import TransformPen
from fontTools.pens.ttGlyphPen import TTGlyphPen
from fontTools.ttLib import TTFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONTS = os.path.join(ROOT, "assets", "fonts")

# The angle Inter's own italic uses, so the new faces sit with the shipped one.
ANGLE = -9.4

# Hinting is written against the upright outlines, so it is dropped rather than
# left to fight the slant.
DROP = ("cvt ", "fpgm", "prep")

FACES = [
    {
        "src": "Inter-Regular.ttf",
        "out": "Inter-Italic.ttf",
        "names": {1: "Inter", 2: "Italic", 4: "Inter Italic", 6: "Inter-Italic"},
    },
    {
        "src": "Inter-SemiBold.ttf",
        "out": "Inter-SemiBoldItalic.ttf",
        "names": {1: "Inter SemiBold", 2: "Italic", 4: "Inter SemiBold Italic",
                  6: "Inter-SemiBoldItalic", 16: "Inter", 17: "SemiBold Italic"},
    },
]


def slant(path_in, path_out, names):
    font = TTFont(path_in)
    glyphset = font.getGlyphSet()
    glyf = font["glyf"]
    shear = Transform(1, 0, math.tan(math.radians(-ANGLE)), 1, 0, 0)

    built = {}
    for name in font.getGlyphOrder():
        # Components carry transforms of their own, so every glyph is flattened
        # first; slanting a composite and its parts would slant twice.
        recorder = DecomposingRecordingPen(glyphset)
        glyphset[name].draw(recorder)
        pen = TTGlyphPen(None)
        recorder.replay(TransformPen(pen, shear))
        built[name] = pen.glyph()

    for name, glyph in built.items():
        glyf[name] = glyph
        glyph.recalcBounds(glyf)

    font["head"].macStyle = font["head"].macStyle | 0x02
    font["OS/2"].fsSelection = (font["OS/2"].fsSelection & ~0x40) | 0x01
    font["post"].italicAngle = ANGLE

    for record in list(font["name"].names):
        if record.nameID in names:
            record.string = names[record.nameID]
    for name_id, value in names.items():
        if not font["name"].getName(name_id, 3, 1, 0x409):
            font["name"].setName(value, name_id, 3, 1, 0x409)

    for tag in DROP:
        if tag in font:
            del font[tag]

    font.save(path_out)
    return os.path.getsize(path_out)


def main():
    for face in FACES:
        size = slant(os.path.join(FONTS, face["src"]), os.path.join(FONTS, face["out"]), face["names"])
        print("%s -> %s (%d bytes)" % (face["src"], face["out"], size))


if __name__ == "__main__":
    main()
