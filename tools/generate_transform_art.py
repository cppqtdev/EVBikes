#!/usr/bin/env python3
"""Draws the shapes that have to be images because Qt for MCUs only
transforms Image, Text and StaticText - never Item or Rectangle.

White on transparent, stored as Alpha8 and tinted in QML, like the rest of
the single-colour art.
Outputs: assets/cluster/needle_amp.png, card_tilt.png, preride_rule.png
Run: python3 tools/generate_transform_art.py
"""
import os

from PIL import Image, ImageChops, ImageDraw

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "cluster")
SS = 4


def save(img, name):
    img.save(os.path.join(OUT, name + ".png"))
    print(" ", name, img.size)


def rounded_bar(w, h, radius):
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([0, 0, w * SS - 1, h * SS - 1], radius=radius * SS,
                        fill=(255, 255, 255, 255))
    return img.resize((w, h), Image.LANCZOS)


def needle():
    """132x5 stadium whose alpha follows the old gradient: 0 at the pivot,
    0xB0 at 0.35, opaque at the tip."""
    w, h = 132, 5
    shape = rounded_bar(w, h, 2.5).split()[3]
    ramp = Image.new("L", (w, h))
    px = ramp.load()
    for x in range(w):
        t = x / (w - 1)
        a = (t / 0.35) * 0xB0 if t <= 0.35 else 0xB0 + ((t - 0.35) / 0.65) * (255 - 0xB0)
        for y in range(h):
            px[x, y] = int(round(a))
    out = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    out.putalpha(ImageChops.multiply(shape, ramp))
    return out


print("writing:")
save(needle(), "needle_amp")
save(rounded_bar(200, 96, 10), "card_tilt")
save(rounded_bar(168, 2, 1), "preride_rule")
