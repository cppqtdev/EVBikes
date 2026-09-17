#!/usr/bin/env python3
"""Fails when the art generator draws a shape at one times.

Most of the sharpness faults in this UI came from the same habit: a mask drawn
straight onto a 1280 x 480 canvas keeps every step of the staircase it was drawn
with, and those steps survive into whatever the mask is multiplied into. The
rule in this file is to draw at SS and downsample, or to use polygon_mask.

A shape that is blurred afterwards is exempt: a wide blur removes the staircase
along with everything else.

    python3 tools/art_check.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(ROOT, "tools", "generate_cluster_art.py")

# A canvas at screen size rather than at SS.
CANVAS = re.compile(r"^\s*(\w+)\s*=\s*Image\.new\(\"L\",\s*\(W,\s*H\)")
# Draws whose edge follows something other than the pixel grid.
SHAPED = re.compile(r"ImageDraw\.Draw\((\w+)\)\.(polygon|ellipse|arc|chord|pieslice|rounded_rectangle)\(")
BLUR = re.compile(r"GaussianBlur\((\d+)\)")
# Below this the blur leaves the staircase showing.
BLUR_HIDES = 5
LOOKAHEAD = 8


def problems(path):
    lines = open(path, encoding="utf-8").read().split("\n")
    found = []
    for number, line in enumerate(lines):
        canvas = CANVAS.match(line)
        if not canvas:
            continue
        name = canvas.group(1)
        window = lines[number:number + LOOKAHEAD]
        shape = None
        for text in window:
            match = SHAPED.search(text)
            if match and match.group(1) == name:
                shape = match.group(2)
                break
        if shape is None:
            continue
        blurred = False
        for text in window:
            if name in text:
                for radius in BLUR.findall(text):
                    if int(radius) >= BLUR_HIDES:
                        blurred = True
        if not blurred:
            found.append((number + 1, name, shape))
    return found


if __name__ == "__main__":
    hits = problems(sys.argv[1] if len(sys.argv) > 1 else TARGET)
    for number, name, shape in hits:
        print("%s:%d: %s draws a %s at one times; draw at SS or use polygon_mask"
              % (os.path.relpath(TARGET, ROOT), number, name, shape))
    print("art_check: %d problem(s)" % len(hits))
    sys.exit(1 if hits else 0)
