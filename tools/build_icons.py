#!/usr/bin/env python3
"""Rasterise the icon masters in assets/icons/src to white PNGs.

Qt for MCUs draws an image at its own size, so a telltale shown at 24 px wants
a 24 px file: a 40 px one scaled down loses the thin strokes, which is what
made the old set look soft. One master per symbol, one PNG per size it is
shown at.

White is not a style choice either. ColorizedImage tints the alpha channel, so
the artwork carries shape only, and sync_project_files.py picks the Alpha8
format for an image whose visible pixels are all pure white, which halves what
it costs in flash.

A master is an .svg, which is what to ask a library for, or a .png, which is
what most of them hand over by default. A downloaded PNG is only ever as good
as the size it came at, so it is used as-is when it already matches and
reduced when it is larger, never enlarged.

Pillow is the only requirement. The SVG subset understood here is the one the
masters use: path, circle, ellipse, line, polyline, polygon and rect, with
stroke, stroke-width, stroke-linecap and fill, inherited through g.
"""

import math
import os
import re
import sys
import xml.etree.ElementTree as ET

from PIL import Image, ImageDraw

SS = 8                    # supersampling; the edges come from the downscale
CURVE_STEPS = 24

NUM = re.compile(r"[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?")
CMD = re.compile(r"[MmLlHhVvCcSsQqTtAaZz]")


def numbers(text):
    return [float(v) for v in NUM.findall(text or "")]


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def cubic(p0, p1, p2, p3, steps=CURVE_STEPS):
    out = []
    for i in range(1, steps + 1):
        t = i / steps
        a, b, c = lerp(p0, p1, t), lerp(p1, p2, t), lerp(p2, p3, t)
        d, e = lerp(a, b, t), lerp(b, c, t)
        out.append(lerp(d, e, t))
    return out


def quad(p0, p1, p2, steps=CURVE_STEPS):
    out = []
    for i in range(1, steps + 1):
        t = i / steps
        a, b = lerp(p0, p1, t), lerp(p1, p2, t)
        out.append(lerp(a, b, t))
    return out


def arc(p0, rx, ry, rot, large, sweep, p1, steps=CURVE_STEPS):
    """SVG elliptical arc, endpoint form, flattened to points."""
    if rx == 0 or ry == 0 or p0 == p1:
        return [p1]
    rx, ry = abs(rx), abs(ry)
    phi = math.radians(rot)
    cs, sn = math.cos(phi), math.sin(phi)
    dx, dy = (p0[0] - p1[0]) / 2, (p0[1] - p1[1]) / 2
    x1, y1 = cs * dx + sn * dy, -sn * dx + cs * dy
    scale = (x1 * x1) / (rx * rx) + (y1 * y1) / (ry * ry)
    if scale > 1:
        rx, ry = rx * math.sqrt(scale), ry * math.sqrt(scale)
    num = rx * rx * ry * ry - rx * rx * y1 * y1 - ry * ry * x1 * x1
    den = rx * rx * y1 * y1 + ry * ry * x1 * x1
    co = math.sqrt(max(0.0, num / den)) * (-1 if large == sweep else 1)
    cx1, cy1 = co * rx * y1 / ry, -co * ry * x1 / rx
    cx = cs * cx1 - sn * cy1 + (p0[0] + p1[0]) / 2
    cy = sn * cx1 + cs * cy1 + (p0[1] + p1[1]) / 2

    def angle(ux, uy, vx, vy):
        d = (ux * vx + uy * vy) / (math.hypot(ux, uy) * math.hypot(vx, vy))
        a = math.acos(max(-1.0, min(1.0, d)))
        return -a if ux * vy - uy * vx < 0 else a

    start = angle(1, 0, (x1 - cx1) / rx, (y1 - cy1) / ry)
    delta = angle((x1 - cx1) / rx, (y1 - cy1) / ry, (-x1 - cx1) / rx, (-y1 - cy1) / ry)
    if not sweep and delta > 0:
        delta -= 2 * math.pi
    elif sweep and delta < 0:
        delta += 2 * math.pi
    out = []
    for i in range(1, steps + 1):
        a = start + delta * i / steps
        x, y = rx * math.cos(a), ry * math.sin(a)
        out.append((cs * x - sn * y + cx, sn * x + cs * y + cy))
    return out


def parse_path(d):
    """A path as a list of (points, closed) subpaths."""
    tokens, last = [], 0
    for m in CMD.finditer(d):
        if m.start() > last:
            tokens.append(d[last:m.start()])
        tokens.append(m.group())
        last = m.end()
    if last < len(d):
        tokens.append(d[last:])

    subs, pts = [], []
    cur = (0.0, 0.0)
    start = (0.0, 0.0)
    prev_c = None
    cmd = None
    i = 0
    while i < len(tokens):
        t = tokens[i].strip()
        i += 1
        if not t:
            continue
        if CMD.fullmatch(t):
            cmd = t
            if cmd in "Zz":
                if pts:
                    subs.append((pts, True))
                    pts = []
                cur = start
                continue
            args = numbers(tokens[i]) if i < len(tokens) and not CMD.fullmatch(tokens[i].strip()) else []
            if args:
                i += 1
        else:
            args = numbers(t)
        rel = cmd.islower()
        k = cmd.upper()
        j = 0
        while j < len(args):
            if k == "M":
                p = (args[j] + (cur[0] if rel else 0), args[j + 1] + (cur[1] if rel else 0))
                j += 2
                if pts:
                    subs.append((pts, False))
                pts = [p]
                cur = start = p
                k = "L"          # further pairs after an M are implicit lines
            elif k == "L":
                p = (args[j] + (cur[0] if rel else 0), args[j + 1] + (cur[1] if rel else 0))
                j += 2
                pts.append(p)
                cur = p
            elif k == "H":
                p = (args[j] + (cur[0] if rel else 0), cur[1])
                j += 1
                pts.append(p)
                cur = p
            elif k == "V":
                p = (cur[0], args[j] + (cur[1] if rel else 0))
                j += 1
                pts.append(p)
                cur = p
            elif k in ("C", "S"):
                if k == "C":
                    c1 = (args[j] + (cur[0] if rel else 0), args[j + 1] + (cur[1] if rel else 0))
                    c2 = (args[j + 2] + (cur[0] if rel else 0), args[j + 3] + (cur[1] if rel else 0))
                    p = (args[j + 4] + (cur[0] if rel else 0), args[j + 5] + (cur[1] if rel else 0))
                    j += 6
                else:
                    c1 = (2 * cur[0] - prev_c[0], 2 * cur[1] - prev_c[1]) if prev_c else cur
                    c2 = (args[j] + (cur[0] if rel else 0), args[j + 1] + (cur[1] if rel else 0))
                    p = (args[j + 2] + (cur[0] if rel else 0), args[j + 3] + (cur[1] if rel else 0))
                    j += 4
                pts.extend(cubic(cur, c1, c2, p))
                prev_c, cur = c2, p
                continue
            elif k == "Q":
                c1 = (args[j] + (cur[0] if rel else 0), args[j + 1] + (cur[1] if rel else 0))
                p = (args[j + 2] + (cur[0] if rel else 0), args[j + 3] + (cur[1] if rel else 0))
                j += 4
                pts.extend(quad(cur, c1, p))
                cur = p
            elif k == "A":
                p = (args[j + 5] + (cur[0] if rel else 0), args[j + 6] + (cur[1] if rel else 0))
                pts.extend(arc(cur, args[j], args[j + 1], args[j + 2],
                               int(args[j + 3]), int(args[j + 4]), p))
                j += 7
                cur = p
            else:
                break
            prev_c = None
    if pts:
        subs.append((pts, False))
    return subs


def shapes(node, inherited):
    """(subpaths, style) for one element, with g attributes inherited."""
    style = dict(inherited)
    for key in ("stroke", "fill", "stroke-width", "stroke-linecap"):
        if node.get(key) is not None:
            style[key] = node.get(key)
    tag = node.tag.split("}")[-1]
    f = float
    if tag == "path":
        return parse_path(node.get("d", "")), style
    if tag in ("circle", "ellipse"):
        cx, cy = f(node.get("cx", 0)), f(node.get("cy", 0))
        rx = f(node.get("r", node.get("rx", 0)))
        ry = f(node.get("r", node.get("ry", 0)))
        pts = [(cx + rx * math.cos(a * math.pi / 32), cy + ry * math.sin(a * math.pi / 32))
               for a in range(65)]
        return [(pts, True)], style
    if tag == "line":
        return [([(f(node.get("x1", 0)), f(node.get("y1", 0))),
                  (f(node.get("x2", 0)), f(node.get("y2", 0)))], False)], style
    if tag in ("polyline", "polygon"):
        v = numbers(node.get("points", ""))
        return [(list(zip(v[0::2], v[1::2])), tag == "polygon")], style
    if tag == "rect":
        x, y = f(node.get("x", 0)), f(node.get("y", 0))
        w, h = f(node.get("width", 0)), f(node.get("height", 0))
        return [([(x, y), (x + w, y), (x + w, y + h), (x, y + h)], True)], style
    return [], style


def collect(node, inherited, out):
    style = dict(inherited)
    for key in ("stroke", "fill", "stroke-width", "stroke-linecap"):
        if node.get(key) is not None:
            style[key] = node.get(key)
    tag = node.tag.split("}")[-1]
    if tag not in ("svg", "g"):
        subs, st = shapes(node, inherited)
        if subs:
            out.append((subs, st))
    for child in node:
        collect(child, style, out)


def render(svg_path, size):
    root = ET.parse(svg_path).getroot()
    box = numbers(root.get("viewBox") or "0 0 24 24")
    vx, vy, vw, vh = box if len(box) == 4 else (0, 0, 24, 24)
    k = size * SS / max(vw, vh)

    mask = Image.new("L", (size * SS, size * SS), 0)
    draw = ImageDraw.Draw(mask)
    items = []
    collect(root, {"fill": "none", "stroke": "none", "stroke-width": "1",
                   "stroke-linecap": "butt"}, items)

    for subs, st in items:
        width = float(st.get("stroke-width", 1)) * k
        stroked = st.get("stroke", "none") != "none"
        filled = st.get("fill", "none") != "none"
        round_cap = st.get("stroke-linecap", "butt") == "round"
        for pts, closed in subs:
            p = [((x - vx) * k, (y - vy) * k) for x, y in pts]
            if len(p) < 2:
                continue
            if filled:
                draw.polygon(p, fill=255)
            if not stroked:
                continue
            line = p + [p[0]] if closed else p
            draw.line(line, fill=255, width=max(1, int(round(width))), joint="curve")
            if round_cap and not closed:
                r = width / 2
                for end in (p[0], p[-1]):
                    draw.ellipse([end[0] - r, end[1] - r, end[0] + r, end[1] + r], fill=255)

    mask = mask.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.putalpha(mask)
    return out


def from_png(path, size):
    """A downloaded PNG, turned into the white-on-alpha shape.

    Artwork arrives black on transparency, or black on an opaque white card.
    Either way the shape is what is dark or what is opaque, so take whichever
    of the two actually carries it and throw the colour away.
    """
    im = Image.open(path).convert("RGBA")
    alpha = im.split()[3]
    if alpha.getextrema()[0] > 250:
        #  No transparency at all: the card is opaque, so the ink is the dark
        #  pixels and the paper is what has to go.
        grey = im.convert("L")
        alpha = grey.point(lambda v: 255 - v)
    if im.size != (size, size):
        alpha = alpha.resize((size, size), Image.LANCZOS)
    out = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    out.putalpha(alpha)
    return out


def main(argv):
    here = os.path.dirname(os.path.abspath(__file__))
    root = os.path.dirname(here)
    src = os.path.join(root, "assets", "icons", "src")
    if not os.path.isdir(src):
        print(f"no masters in {src}", file=sys.stderr)
        return 1

    #  Each master says which sizes it is wanted at, in its own file name:
    #  tt_abs.24.32.svg becomes assets/icons/24/tt_abs.png and .../32/tt_abs.png.
    made, thin = 0, []
    for f in sorted(os.listdir(src)):
        if not f.lower().endswith((".svg", ".png")):
            continue
        parts = f.rsplit(".", 1)[0].split(".")
        name, sizes = parts[0], [int(s) for s in parts[1:]] or [24]
        path = os.path.join(src, f)
        for size in sizes:
            out = os.path.join(root, "assets", "icons", str(size))
            os.makedirs(out, exist_ok=True)
            if f.lower().endswith(".svg"):
                img = render(path, size)
            else:
                img = from_png(path, size)
                w = Image.open(path).width
                if w < size:
                    thin.append(f"{f} is {w}px and is wanted at {size}px")
            img.save(os.path.join(out, name + ".png"))
            made += 1
            if argv and argv[0] == "-v":
                print(f"{name}.png -> {size}")
    for warning in sorted(set(thin)):
        print(f"build_icons: {warning}; ask the library for the SVG")
    print(f"build_icons: {made} file(s)")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
