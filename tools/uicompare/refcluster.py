#!/usr/bin/env python3
"""Turns a 1920x1080 reference frame into the 1280x480 cluster rectangle.

The cluster fills the frame width, so x maps by 1.5 exactly. Vertically the
frame carries 192 rows above the cluster: the housing top edge, 576 cluster
pixels wide, lands on frame row 198 in every clean ride frame.
"""
import sys
import numpy as np
from PIL import Image

Y_OFFSET = 187.5
SCALE = 1.5


def to_cluster(path):
    img = Image.open(path).convert("RGB")
    box = (0, int(Y_OFFSET), img.width, int(Y_OFFSET) + int(480 * SCALE))
    return img.crop(box).resize((1280, 480), Image.LANCZOS)


if __name__ == "__main__":
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) > 2 else ".cmp/ref_cluster.png"
    to_cluster(src).save(dst)
    print(dst)
