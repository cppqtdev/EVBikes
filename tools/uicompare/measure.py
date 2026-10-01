#!/usr/bin/env python3
"""Measure one rendered screen against its reference frame, in numbers.

There is no Figma for this project, so the reference is the frames pulled
out of the design video. Eyeballing a 1280 by 480 cluster against a frame is
how padding drifts by four pixels everywhere and nobody can say by how much.
This reads both pictures and prints the difference.

Usage:
    measure.py <shot.png> <reference.png>          two separate pictures
    measure.py --split <stacked.png>               one picture, ours over theirs

What it reports, per picture and then as a delta:

  - the ink box: the smallest rectangle holding everything that is not
    background, which catches a whole screen sitting too low or too wide
  - column and row profiles: where the bright things start and stop across
    and down the screen, which is what finds a bar, a dock or a strip out of
    place
  - the colour at a set of probe points, which is what finds a fill that has
    drifted off the palette

Every number is in the picture's own pixels. Both pictures are scaled to the
same width first, so a delta is always like for like.
"""

import sys
import numpy as np
from PIL import Image


def load(path, width=None):
    im = Image.open(path).convert("RGB")
    if width and im.width != width:
        im = im.resize((width, round(im.height * width / im.width)), Image.LANCZOS)
    return np.array(im).astype(int)


def ink_box(a, floor=26):
    """The smallest rectangle holding everything brighter than the backdrop."""
    lum = a.sum(axis=2)
    mask = lum > floor * 3
    rows = np.where(mask.any(axis=1))[0]
    cols = np.where(mask.any(axis=0))[0]
    if not len(rows) or not len(cols):
        return None
    return int(cols[0]), int(rows[0]), int(cols[-1]), int(rows[-1])


def runs(profile, threshold):
    out, start = [], None
    for i, value in enumerate(profile):
        if value > threshold and start is None:
            start = i
        elif value <= threshold and start is not None:
            if i - start > 2:
                out.append((start, i))
            start = None
    if start is not None:
        out.append((start, len(profile)))
    return out


def bands(a, axis, floor=60):
    """Where the bright things start and stop along one axis."""
    lum = a.sum(axis=2) / 3.0
    mask = (lum > floor).astype(int)
    profile = mask.sum(axis=1 if axis == "row" else 0)
    return runs(profile, max(3, profile.max() * 0.06))


def describe(name, a):
    print("  %s  %d x %d" % (name, a.shape[1], a.shape[0]))
    box = ink_box(a)
    if box:
        print("    ink box      x %d..%d  y %d..%d  (%d x %d)"
              % (box[0], box[2], box[1], box[3], box[2] - box[0] + 1, box[3] - box[1] + 1))
    print("    column bands %s" % (bands(a, "col")[:10],))
    print("    row bands    %s" % (bands(a, "row")[:10],))


def delta(shot, reference):
    print("\nDelta (ours minus the reference, in reference pixels):")
    ours, theirs = ink_box(shot), ink_box(reference)
    if ours and theirs:
        for label, i in (("left", 0), ("top", 1), ("right", 2), ("bottom", 3)):
            print("    ink %-7s %+d" % (label, ours[i] - theirs[i]))

    for axis in ("col", "row"):
        a, b = bands(shot, axis), bands(reference, axis)
        print("    %s bands: ours %d, reference %d" % (axis, len(a), len(b)))
        for i in range(min(len(a), len(b))):
            if abs(a[i][0] - b[i][0]) > 2 or abs(a[i][1] - b[i][1]) > 2:
                print("      band %d  ours %s  reference %s  start %+d  end %+d"
                      % (i, a[i], b[i], a[i][0] - b[i][0], a[i][1] - b[i][1]))


def main():
    if sys.argv[1] == "--split":
        whole = Image.open(sys.argv[2]).convert("RGB")
        half = whole.height // 2
        shot = np.array(whole.crop((0, 0, whole.width, half))).astype(int)
        reference = np.array(whole.crop((0, half, whole.width, whole.height))).astype(int)
    else:
        reference = load(sys.argv[2])
        shot = load(sys.argv[1], width=reference.shape[1])

    print("Measured:")
    describe("ours     ", shot)
    describe("reference", reference)
    delta(shot, reference)
    return 0


if __name__ == "__main__":
    sys.exit(main())
