#!/usr/bin/env python3
"""Composites the cluster frame from its art, in the order ShellFrame draws it.

Qt is not reachable from this shell, so this is how a frame change is checked
against a reference frame without running the app. It covers the shell, the
housings and the glow - everything ShellFrame paints, and nothing above it.
"""
import os
import sys

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ART = os.path.join(ROOT, "assets", "cluster")

# name, tint, opacity - the order ShellFrame paints them in for the ride screen
LAYERS = [
    ("shell_backing", "#000000", 1.0),
    ("shell_ride", "#070709", 1.0),
    ("shell_vignette", "#FFFFFF", 0.06),
    ("panel_haze", "#57F2C9", 0.22),
    ("bar_channel", "#010101", 1.0),
    ("housing_top", "#141414", 1.0),
    ("housing_bottom", "#141414", 1.0),
    ("housing_light", "#FFFFFF", 0.35),
    ("glow_ride", "#57F2C9", 1.0),
    ("bar_edge", "#57F2C9", 0.45),
]


def tinted(name, colour, opacity):
    src = Image.open(os.path.join(ART, name + ".png")).convert("RGBA")
    rgb = tuple(int(colour[i:i + 2], 16) for i in (1, 3, 5))
    layer = Image.new("RGBA", src.size, rgb + (255,))
    alpha = src.split()[3]
    if opacity < 1.0:
        alpha = alpha.point(lambda v: int(v * opacity))
    layer.putalpha(alpha)
    return layer


def paint():
    out = Image.new("RGBA", (1280, 480), (0, 0, 0, 255))
    for name, colour, opacity in LAYERS:
        out.alpha_composite(tinted(name, colour, opacity))
    return out.convert("RGB")


if __name__ == "__main__":
    dst = sys.argv[1] if len(sys.argv) > 1 else ".cmp/shell_sim.png"
    paint().save(dst)
    print(dst)
