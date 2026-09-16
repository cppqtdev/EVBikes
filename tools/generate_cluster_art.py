#!/usr/bin/env python3
"""Generates the 1280x480 cluster shell artwork and bar geometry.

All art is original, drawn from geometry measured on the reference screens.
Single-colour art is white on transparent (stored as Alpha8, tinted in QML).
Outputs:
  assets/cluster/*.png
  qml/components/PowerBar.qml   (generated, left AMP bar)
  qml/components/RpmBar.qml     (generated, right RPM bar)
Run: python3 tools/generate_cluster_art.py
"""
import math
import os

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "assets", "cluster")
QML = os.path.join(ROOT, "qml", "components")
W, H = 1280, 480
SS = 3
WHITE = (255, 255, 255, 255)

# Geometry measured on reference frames frame_010 (auth) and frame_020 (ride),
# mapped as x / 1.5, y / 1.5 - 125.

# Auth / splash body outline
SHELL = [(363, 5), (141.7, 35), (80.7, 137.7), (158.5, 368.5), (351.3, 461.7),
         (928.7, 461.7), (1121.5, 368.5), (1199.3, 137.7), (1138.3, 35), (938, 5)]
# The chamfer is slightly less steep than it was: the reference lip sits about
# four and a half pixels outside ours at rows 38 and 50, where the interior is
# dark enough to locate it, while the 576 px top edge is unchanged.
HOUSING_TOP = [(362, 4), (938, 4), (886.5, 54), (431.5, 54)]
HOUSING_BOTTOM = [(416, 410), (864, 410), (929, 458), (351, 458)]

# Ride glow contour, left half: (point, fillet radius)
RIDE_GLOW = [((250, 18.8), 0), ((150, 32), 16), ((88.3, 150.3), 14), ((162.6, 368.8), 24),
             ((350, 456.7), 5), ((416, 406.3), 5), ((545, 406.3), 0)]
RIDE_TOP = (362, 4)

# Bar centre line (top cut centre -> knee -> end cut centre), width and gap
BAR_TOP, BAR_KNEE, BAR_END = (122.1, 110.0), (199.5, 337.7), (360.0, 418.5)
BAR_WIDTH = 35
BAR_GAP = 3
BAR_KNEE_RADIUS = 30
# Segment boundaries, bottom end first: (outer point, inner point)
BAR_CUTS = [((345.0, 430.0), (375.0, 408.3)),
            ((298.3, 406.7), (328.3, 386.7)),
            ((255.0, 385.0), (285.0, 364.3)),
            ((215.0, 365.0), (245.0, 341.7)),
            ((176.7, 325.0), (208.3, 308.3)),
            ((160.0, 273.3), (191.7, 253.3)),
            ((141.7, 221.7), (175.0, 198.3)),
            ((125.0, 174.3), (156.0, 146.7)),
            ((109.3, 126.7), (135.0, 93.3))]
BAR_SEGMENTS = len(BAR_CUTS) - 1


def canvas(w=W, h=H, scale=SS):
    img = Image.new("RGBA", (w * scale, h * scale), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def sc(points, scale=SS):
    return [(x * scale, y * scale) for x, y in points]


def down(img, w=W, h=H):
    return img.resize((w, h), Image.LANCZOS)


def save(img, name):
    os.makedirs(OUT, exist_ok=True)
    img.save(os.path.join(OUT, name + ".png"))


def mirror_x(points, width=W):
    return [(width - x, y) for x, y in points]


def lerp(a, b, t):
    return (a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t)


def unit(a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    ln = math.hypot(dx, dy)
    return (dx / ln, dy / ln)


def rounded(points, radii, steps=32):
    """Polyline with quadratic fillets of the given radius at each interior point."""
    out = [points[0]]
    for i in range(1, len(points) - 1):
        p0, p1, p2 = points[i - 1], points[i], points[i + 1]
        r = radii[i]
        if r <= 0:
            out.append(p1)
            continue
        u1, u2 = unit(p1, p0), unit(p1, p2)
        a = (p1[0] + u1[0] * r, p1[1] + u1[1] * r)
        b = (p1[0] + u2[0] * r, p1[1] + u2[1] * r)
        for s in range(steps + 1):
            t = s / steps
            out.append(((1 - t) ** 2 * a[0] + 2 * (1 - t) * t * p1[0] + t * t * b[0],
                        (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * p1[1] + t * t * b[1]))
    out.append(points[-1])
    return out


def ride_glow_left(inset=0.0):
    pts = [p for p, _ in RIDE_GLOW]
    radii = [r for _, r in RIDE_GLOW]
    path = rounded(pts, radii)
    if inset == 0:
        return path
    return offset_path(path, inset)


def offset_path(path, d):
    """Offset an open polyline; positive d moves to the right of travel (inward here)."""
    out = []
    n = len(path)
    for i in range(n):
        a = path[max(0, i - 1)]
        b = path[min(n - 1, i + 1)]
        if a == b:
            out.append(path[i])
            continue
        ux, uy = unit(a, b)
        out.append((path[i][0] - uy * d, path[i][1] + ux * d))
    return out


def fade_mask(ranges):
    """L mask: 255 everywhere except linear fades. ranges: (axis, start, end) ramping 0 -> 255."""
    mask = Image.new("L", (W, H), 255)
    arr = mask.load()
    for axis, start, end in ranges:
        for i in range(W if axis == "x" else H):
            t = (i - start) / (end - start)
            v = int(255 * max(0.0, min(1.0, t)))
            if v >= 255:
                continue
            if axis == "x":
                for y in range(H):
                    arr[i, y] = min(arr[i, y], v)
            else:
                for x in range(W):
                    arr[x, i] = min(arr[x, i], v)
    return mask


def symmetric(mask_left):
    return ImageChops.lighter(mask_left, mask_left.transpose(Image.FLIP_LEFT_RIGHT))


def alpha_image(mask):
    layer = Image.new("RGBA", mask.size, (255, 255, 255, 0))
    layer.putalpha(mask)
    return layer


def vertical_ramp(y0, y1, a0, a1):
    g = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(g)
    for y in range(H):
        t = max(0.0, min(1.0, (y - y0) / (y1 - y0)))
        gd.line([(0, y), (W, y)], fill=int(a0 + (a1 - a0) * t))
    return g


# ------------------------------------------------------------------ shell
def ride_body_polygon():
    pts = [RIDE_TOP] + [p for p, _ in RIDE_GLOW[:5]]
    left = rounded(pts, [0] + [r for _, r in RIDE_GLOW[:4]] + [0], steps=24)
    right = [(W - x, y) for x, y in reversed(left)]
    return left + right


def make_shell():
    img, d = canvas()
    d.polygon(sc(SHELL), fill=WHITE)
    save(down(img), "shell_fill")

    img, d = canvas()
    d.polygon(sc(ride_body_polygon()), fill=WHITE)
    save(down(img), "shell_ride")

    img, d = canvas()
    pts = sc(SHELL)
    d.line(pts + [pts[0]], fill=WHITE, width=int(1.5 * SS), joint="curve")
    edge = down(img).getchannel("A")
    save(alpha_image(ImageChops.multiply(edge, vertical_ramp(20, 260, 70, 255))), "shell_edge")

    # centre lift: the middle of the panel is slightly lighter than the edges
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(SHELL, fill=255)
    ride = Image.new("L", (W, H), 0)
    ImageDraw.Draw(ride).polygon(ride_body_polygon(), fill=255)
    mask = ImageChops.multiply(mask, ride)
    lift = Image.new("L", (W, H), 0)
    ImageDraw.Draw(lift).ellipse([290, 60, 990, 440], fill=255)
    lift = lift.filter(ImageFilter.GaussianBlur(90))
    save(alpha_image(ImageChops.multiply(mask, lift)), "shell_vignette")

    # housings: lighter top face fading down
    img, d = canvas()
    d.polygon(sc(HOUSING_TOP), fill=WHITE)
    # Soften the chamfer: across the reference's sloped end a horizontal cut
    # ramps up over about twenty pixels, where a hard polygon steps in one.
    top_face = down(img).getchannel("A").filter(ImageFilter.GaussianBlur(3))
    face = top_face
    # The reference top housing fades all the way out before its bottom edge:
    # measured over #141414 it runs 255 at y8 down to about 13 at y52, so it
    # dissolves into the screen instead of ending on a line.
    save(alpha_image(ImageChops.multiply(face, vertical_ramp(4, 54, 255, 0))), "housing_top")
    img, d = canvas()
    d.polygon(sc(HOUSING_BOTTOM), fill=WHITE)
    face = down(img).getchannel("A")
    save(alpha_image(ImageChops.multiply(face, vertical_ramp(410, 458, 255, 150))), "housing_bottom")

    # bevel highlight along the housing edges and a soft spill below the top housing
    # The glow under the strip is a step, not a blob: the reference jumps from
    # #010101 at row 52 to #171616 at row 56 and then decays slowly. A hard
    # band with a downward ramp and only a light blur reproduces that; a
    # Gaussian blob washes the step out and lifts the housing above it.
    band = Image.new("L", (W, H), 0)
    ImageDraw.Draw(band).polygon([(432, 55), (886, 55), (876, 88), (442, 88)], fill=255)
    spill = ImageChops.multiply(band, vertical_ramp(55, 88, 72, 0)).filter(ImageFilter.GaussianBlur(2))
    bevel = Image.new("L", (W * SS, H * SS), 0)
    bd = ImageDraw.Draw(bevel)
    # The top housing has a bevel on its two chamfered ends only, never along
    # the top or bottom edge, and it strengthens downwards: measured against
    # the interior beside it the reference lip is about +1 at row 14, +5 at
    # row 26, +13 at row 38 and +17 at row 50. The old fill of 230 across the
    # whole outline is what drew a white box around the telltales.
    chamfer = Image.new("L", (W * SS, H * SS), 0)
    cd = ImageDraw.Draw(chamfer)
    cd.line(sc([HOUSING_TOP[0], HOUSING_TOP[3]]), fill=255, width=int(1.4 * SS))
    cd.line(sc([HOUSING_TOP[2], HOUSING_TOP[1]]), fill=255, width=int(1.4 * SS))
    chamfer = ImageChops.multiply(chamfer.resize((W, H), Image.LANCZOS), vertical_ramp(10, 54, 0, 55))
    # The housing also throws a soft halo outside its chamfered ends, which is
    # what gives it weight against the black. Measured on a column just outside
    # the left chamfer the reference runs 21 at row 32 down to 3 at row 54.
    halo = ImageChops.subtract(top_face.filter(ImageFilter.GaussianBlur(12)), top_face)
    halo = halo.point(lambda v: min(255, int(v * 0.7)))
    bd.line(sc([HOUSING_BOTTOM[3], HOUSING_BOTTOM[0], HOUSING_BOTTOM[1], HOUSING_BOTTOM[2]]), fill=150, width=int(1.2 * SS), joint="curve")
    bevel = bevel.resize((W, H), Image.LANCZOS)
    lit = ImageChops.lighter(ImageChops.lighter(spill, bevel), chamfer)
    save(alpha_image(ImageChops.lighter(lit, halo)), "housing_light")


def stroke(paths, width, scale=SS):
    img = Image.new("L", (W * scale, H * scale), 0)
    d = ImageDraw.Draw(img)
    for p in paths:
        d.line([(x * scale, y * scale) for x, y in p], fill=255, width=max(1, int(width * scale)), joint="curve")
    return img.resize((W, H), Image.LANCZOS)


def draw_glow(paths, core_width, blur, spread_width, halo=0.85):
    halo_mask = stroke(paths, spread_width, 2).filter(ImageFilter.GaussianBlur(blur))
    core = stroke(paths, core_width)
    return ImageChops.lighter(core, halo_mask.point(lambda v: int(v * halo)))


def scale_mask(mask, k):
    return mask.point(lambda v: int(v * k))


def backing_mask():
    body = Image.new("L", (W * SS, H * SS), 0)
    d = ImageDraw.Draw(body)
    d.polygon(sc(SHELL), fill=255)
    d.polygon(sc(ride_body_polygon()), fill=255)
    body = body.resize((W, H), Image.LANCZOS)
    return body.filter(ImageFilter.MaxFilter(29)).filter(ImageFilter.GaussianBlur(2))


def make_backing():
    save(alpha_image(backing_mask()), "shell_backing")


def make_glows():
    backing = backing_mask()
    left = ride_glow_left()
    inner = ride_glow_left(-9)
    fades = symmetric(fade_mask([("x", 250, 170)]))
    fades.paste(255, (0, 60, W, H))
    end_fade = symmetric(fade_mask([("x", 545, 470)]))

    def mirrored(path):
        return [path, mirror_x(path)]

    # The reference contour is tight: a horizontal cut through it is about
    # eight pixels wide in total, where a blur of 7 and a spread of 5 gave ours
    # nearly twenty and washed into the bar beside it.
    main_line = draw_glow(mirrored(left), 2.4, 3, 3)
    second = scale_mask(stroke(mirrored(inner[:-1]), 1.2), 0.55)
    glow = ImageChops.multiply(ImageChops.lighter(main_line, second), fades)
    glow = ImageChops.multiply(ImageChops.multiply(glow, end_fade), backing)
    save(alpha_image(glow), "glow_ride")

    # alert / pre-ride style: three stacked lines fading inward
    base = Image.new("L", (W, H), 0)
    for k, off in enumerate((0, 8, 16)):
        path = ride_glow_left(-off)
        g = draw_glow(mirrored(path), 2.0, 6, 4)
        base = ImageChops.lighter(base, scale_mask(g, 1.0 - k * 0.3))
    base = ImageChops.multiply(ImageChops.multiply(ImageChops.multiply(base, fades), end_fade), backing)
    save(alpha_image(base), "glow_alert")

    # bar channel, inner panel line and the teal haze next to the bars
    seg_union = bar_union_mask()
    channel = seg_union.filter(ImageFilter.MaxFilter(11))
    save(alpha_image(symmetric(channel)), "bar_channel")

    inner_side = inner_side_mask()
    edge_path = offset_path(bar_centre(extend_top=70, extend_end=44), -(BAR_WIDTH / 2 + 8))
    line = ImageChops.multiply(stroke([edge_path], 1.4), vertical_ramp(52, 90, 0, 255))
    save(alpha_image(symmetric(line)), "bar_edge")
    save(alpha_image(line), "bar_edge_left")
    save(alpha_image(channel), "bar_channel_left")

    haze = ImageChops.multiply(seg_union.filter(ImageFilter.MaxFilter(41)).filter(ImageFilter.GaussianBlur(40)), inner_side)
    haze = ImageChops.subtract(haze, seg_union.filter(ImageFilter.MaxFilter(17)))
    save(alpha_image(symmetric(haze)), "panel_haze")


# -------------------------------------------------------------- bar segments
def bar_centre(extend_top=30, extend_end=30):
    top_dir = unit(BAR_KNEE, BAR_TOP)
    end_dir = unit(BAR_KNEE, BAR_END)
    start = (BAR_TOP[0] + top_dir[0] * extend_top, BAR_TOP[1] + top_dir[1] * extend_top)
    stop = (BAR_END[0] + end_dir[0] * extend_end, BAR_END[1] + end_dir[1] * extend_end)
    return rounded([start, BAR_KNEE, stop], [0, BAR_KNEE_RADIUS, 0], steps=24)


def band_mask(scale=SS):
    c = bar_centre()
    outline = offset_path(c, -BAR_WIDTH / 2) + list(reversed(offset_path(c, BAR_WIDTH / 2)))
    img = Image.new("L", (W * scale, H * scale), 0)
    ImageDraw.Draw(img).polygon(sc(outline, scale), fill=255)
    return img


def half_plane_region(p, q, toward, scale=SS):
    """Big polygon covering the side of line p-q that contains `toward`."""
    dx, dy = unit(p, q)
    nx, ny = -dy, dx
    if (toward[0] - p[0]) * nx + (toward[1] - p[1]) * ny < 0:
        nx, ny = -nx, -ny
    far = 4000
    a = (p[0] - dx * far, p[1] - dy * far)
    b = (p[0] + dx * far, p[1] + dy * far)
    return [(a[0] * scale, a[1] * scale), (b[0] * scale, b[1] * scale),
            ((b[0] + nx * far) * scale, (b[1] + ny * far) * scale),
            ((a[0] + nx * far) * scale, (a[1] + ny * far) * scale)]


def segment_masks():
    band = band_mask()
    cut = ImageDraw.Draw(band)
    for outer, inner in BAR_CUTS[1:-1]:
        ux, uy = unit(outer, inner)
        a = (outer[0] - ux * 20, outer[1] - uy * 20)
        b = (inner[0] + ux * 20, inner[1] + uy * 20)
        cut.line(sc([a, b]), fill=0, width=int(BAR_GAP * SS))
    masks = []
    for k in range(BAR_SEGMENTS):
        (oa, ia), (ob, ib) = BAR_CUTS[k], BAR_CUTS[k + 1]
        mid = lerp(lerp(oa, ia, 0.5), lerp(ob, ib, 0.5), 0.5)
        r1 = Image.new("L", band.size, 0)
        ImageDraw.Draw(r1).polygon(half_plane_region(oa, ia, mid), fill=255)
        r2 = Image.new("L", band.size, 0)
        ImageDraw.Draw(r2).polygon(half_plane_region(ob, ib, mid), fill=255)
        masks.append(ImageChops.multiply(ImageChops.multiply(band, r1), r2).resize((W, H), Image.LANCZOS))
    return masks


def bar_union_mask():
    union = Image.new("L", (W, H), 0)
    for m in segment_masks():
        union = ImageChops.lighter(union, m)
    return union.filter(ImageFilter.MaxFilter(7)).filter(ImageFilter.MinFilter(5))


def inner_side_mask():
    """Region on the screen-centre side of the bar centre line (left half)."""
    c = bar_centre()
    first, last = c[0], c[-1]
    poly = [(first[0], -200)] + c + [(last[0] + 400, last[1]), (last[0] + 400, -200)]
    m = Image.new("L", (W, H), 0)
    ImageDraw.Draw(m).polygon(poly, fill=255)
    right = Image.new("L", (W, H), 0)
    ImageDraw.Draw(right).rectangle([0, 0, W // 2, H], fill=255)
    return ImageChops.multiply(m, right)


def make_segments():
    geo_left, geo_right = [], []
    for k, small in enumerate(segment_masks()):
        for side, img_mask, geo in (("l", small, geo_left), ("r", small.transpose(Image.FLIP_LEFT_RIGHT), geo_right)):
            x0, y0, x1, y1 = img_mask.getbbox()
            crop = img_mask.crop((x0, y0, x1, y1))
            save(alpha_image(crop), f"seg_{side}{k}")
            (oa, ia), (ob, ib) = BAR_CUTS[k], BAR_CUTS[k + 1]
            cx, cy = lerp(lerp(oa, ia, 0.5), lerp(ob, ib, 0.5), 0.5)
            if side == "r":
                cx = W - cx
            geo.append((x0, y0, crop.size[0], crop.size[1], cx, cy))
    # remove images left over from an older segment count
    for side in "lr":
        for k in range(BAR_SEGMENTS, 16):
            path = os.path.join(OUT, f"seg_{side}{k}.png")
            if os.path.exists(path):
                os.remove(path)
    return geo_left, geo_right


def write_bar_qml(name, geo, side, comment_label):
    top = BAR_SEGMENTS - 1
    labels = {"l": {top: "MAX", 0: "AMP"}, "r": {top: "× 8", 3: "× 4", 0: "RPM"}}[side]
    lines = [
        "// Generated by tools/generate_cluster_art.py. Do not edit.",
        "import QtQuick",
        "import QtQuickUltralite.Extras",
        "import ClusterCore",
        "",
        f"// {comment_label}. Segment 0 is at the bottom.",
        "Item {",
        "    id: bar",
        "",
        "    property int value: 0",
        f"    property int litCount: Math.round(Math.max(0, Math.min(100, value)) * {BAR_SEGMENTS} / 100)",
        "    property color lowColor: Theme.segLow",
        "    property color highColor: Theme.segHigh",
        "    property color topColor: Theme.segTop",
        "    property color offColor: Theme.segOff",
        "    property bool redZoneTop: false",
        "",
        "    width: 1280",
        "    height: 480",
        "",
    ]
    for k, (x, y, w, h, cx, cy) in enumerate(geo):
        t = k / float(top - 1)
        lines += [
            "    ColorizedImage {",
            f"        x: {x}",
            f"        y: {y}",
            f"        source: \"qrc:/assets/cluster/seg_{side}{k}.png\"",
        ]
        if k == top:
            lines.append(f"        color: bar.redZoneTop ? Theme.segRedZone : (bar.litCount >= {BAR_SEGMENTS} ? bar.topColor : bar.offColor)")
        else:
            lines.append(f"        color: bar.litCount > {k} ? Qt.rgba(bar.lowColor.r + (bar.highColor.r - bar.lowColor.r) * {t:.2f}, "
                         f"bar.lowColor.g + (bar.highColor.g - bar.lowColor.g) * {t:.2f}, "
                         f"bar.lowColor.b + (bar.highColor.b - bar.lowColor.b) * {t:.2f}, 1) : bar.offColor")
        lines += ["    }", ""]
    for k, text in labels.items():
        x, y, w, h, cx, cy = geo[k]
        lines += [
            "    Text {",
            f"        x: {int(round(cx)) - 30}",
            f"        y: {int(round(cy)) - 8}",
            "        width: 60",
            "        horizontalAlignment: Text.AlignHCenter",
            f"        text: \"{text}\"",
        ]
        if k == top and side == "l":
            lines.append("        color: Theme.segLabelOnLight")
        else:
            lines.append("        color: Theme.textPrimary")
        lines += [
            "        font.family: Theme.fontFamily",
            "        font.pixelSize: 12",
            "        font.weight: Font.DemiBold",
            "        font.italic: true",
            "    }",
            "",
        ]
    lines[-1] = "}"
    with open(os.path.join(QML, name + ".qml"), "w") as f:
        f.write("\n".join(lines) + "\n")


# ----------------------------------------------------------- small artwork
def make_trapezoids():
    # mode chip (ECO / SPORTS / ALERT)
    w, h = 96, 48
    img, d = canvas(w, h)
    d.polygon(sc([(0, 0), (w, 0), (w - 6, h), (6, h)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "chip")
    # nav tile
    w, h = 94, 44
    img, d = canvas(w, h)
    d.polygon(sc([(0, 0), (w, 0), (w - 10, h), (10, h)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "tile_slant")
    # Selected settings control: a recessed well with a lit bottom lip.
    # Measured on frame_1318: the left edge runs (770, 414) to (818, 456),
    # the well bottoms out near black, and the last 12 rows lift to #3B3937.
    w, h = 170, 44
    img, d = canvas(w, h)
    d.polygon(sc([(0, 0), (w, 0), (w, h), (48, h)]), fill=WHITE)
    band = img.resize((w, h), Image.LANCZOS)
    save(band, "band_right")
    lip = band.copy()
    ramp = Image.new("L", (w, h))
    pixels = ramp.load()
    for y in range(h):
        bottom = 0.0 if y < h - 12 else (y - (h - 12)) / 11.0
        for x in range(w):
            inward = x - 48.0 * y / h
            side = max(0.0, 1.0 - inward / 55.0) if inward >= 0 else 0.0
            pixels[x, y] = int(255 * min(1.0, max(bottom, side * 0.85)))
    lip.putalpha(ImageChops.multiply(band.split()[3], ramp))
    save(lip, "band_right_lip")
    # ribbons (WARNING / PROTOCOLS / CRASH DETECTED)
    w, h = 340, 30
    img, d = canvas(w, h)
    d.polygon(sc([(0, 0), (w, 0), (w - 22, h), (22, h)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "ribbon")
    # side stand callout parallelogram
    w, h = 240, 32
    img, d = canvas(w, h)
    d.polygon(sc([(22, 0), (w, 0), (w - 22, h), (0, h)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "callout")


def pointed_bar(w, h, point_left, name):
    img, d = canvas(w, h)
    r = h / 2
    if point_left:
        d.polygon(sc([(0, h / 2), (10, 0), (w - r, 0), (w - r, h), (10, h)]), fill=WHITE)
        d.ellipse(sc([(w - h, 0), (w, h)]), fill=WHITE)
    else:
        d.polygon(sc([(r, 0), (w - 10, 0), (w, h / 2), (w - 10, h), (r, h)]), fill=WHITE)
        d.ellipse(sc([(0, 0), (h, h)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), name)


def make_ruler():
    w, h = 190, 12
    img, d = canvas(w, h)
    for i in range(0, w, 4):
        tall = (i // 4) % 5 == 0
        d.line(sc([(i, h), (i, h - (7 if tall else 4))]), fill=WHITE, width=SS)
    save(img.resize((w, h), Image.LANCZOS), "ruler")


def make_card_shapes():
    # tyre alert / crash card: wide rounded octagon
    def octagon(w, h, c):
        return [(c, 0), (w - c, 0), (w, c), (w, h - c), (w - c, h), (c, h), (0, h - c), (0, c)]
    for name, (w, h, c) in {"card_mid": (560, 300, 50)}.items():
        img, d = canvas(w, h)
        d.polygon(sc(octagon(w, h, c)), fill=WHITE)
        save(img.resize((w, h), Image.LANCZOS), name)
        img, d = canvas(w, h)
        p = sc(octagon(w, h, c))
        d.line(p + [p[0]], fill=WHITE, width=2 * SS)
        save(img.resize((w, h), Image.LANCZOS), name + "_edge")


# Alert cards measured on frame_039 (tyre), frame_044 (crash) and frame_046 (SOS), left half.
CARDS = {
    "card_tyre": ([(205, 72), (205, 250), (330, 356)], [40, 50, 24], None, (255, 255)),
    "card_crash": ([(307, 84), (203, 128), (257, 312), (373, 367)], [20, 24, 30, 20], (220, 70), (255, 255)),
    "card_sos": ([(427, 68), (370, 125), (397, 332), (470, 385)], [6, 10, 34, 20], (230, 0), (255, 40)),
}


def make_alert_cards():
    offsets = {}
    for name, (left, radii, edge_alpha, fill_alpha) in CARDS.items():
        right = [(W - x, y) for x, y in reversed(left)]
        pts = left + right
        rr = radii + list(reversed(radii))
        closed = pts + pts[:2]
        path = rounded(closed, [0] + rr[1:] + [rr[0], 0], steps=32)[1:-1]
        mask = Image.new("L", (W * SS, H * SS), 0)
        ImageDraw.Draw(mask).polygon(sc(path), fill=255)
        mask = mask.resize((W, H), Image.LANCZOS)
        top = min(y for _, y in pts)
        bottom = max(y for _, y in pts)
        fill = ImageChops.multiply(mask, vertical_ramp(top, bottom, fill_alpha[0], fill_alpha[1]))
        box = mask.getbbox()
        offsets[name] = box[:2]
        save(alpha_image(fill.crop(box)), name)
        if edge_alpha:
            edge = stroke([path + path[:1]], 1.3)
            edge = ImageChops.multiply(edge, vertical_ramp(top, bottom, edge_alpha[0], edge_alpha[1]))
            save(alpha_image(edge.crop(box)), name + "_edge")
    print("alert card offsets", offsets)


def make_terrain():
    w, h = 660, 270
    img = Image.new("RGBA", (w * 2, h * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    horizon, cx = 12, w / 2

    def height(u, v):
        return (30 * math.sin(u * 3.1 + 0.6) * math.cos(v * 4.3) + 90 * math.exp(-((u - 0.7) ** 2 + (v - 0.85) ** 2) * 6)
                + 70 * math.exp(-((u + 0.8) ** 2 + (v - 0.9) ** 2) * 5) + 40 * math.exp(-((u - 0.1) ** 2 + (v - 0.95) ** 2) * 9))

    def project(u, v):
        depth = 0.12 + v * 1.6
        x = cx + u * w * 0.9 / depth
        y = horizon + 40 + (h - horizon - 40) * (1 - v) ** 1.6 - height(u, v) * (0.35 + (1 - v) * 0.5)
        return x * 2, y * 2

    rows, cols = 38, 50
    for r in range(rows + 1):
        v = r / rows
        pts = [project(-1.4 + 2.8 * c / cols, v) for c in range(cols + 1)]
        alpha = int(40 + 150 * (1 - v))
        d.line(pts, fill=(255, 255, 255, alpha), width=2)
    for c in range(cols + 1):
        u = -1.4 + 2.8 * c / cols
        pts = [project(u, r / rows) for r in range(rows + 1)]
        d.line(pts, fill=(255, 255, 255, 110), width=2)
    img = img.resize((w, h), Image.LANCZOS)
    fade = Image.new("L", (w, h), 0)
    fd = ImageDraw.Draw(fade)
    for y in range(h):
        fd.line([(0, y), (w, y)], fill=int(255 * min(1, y / 60)))
    side = Image.new("L", (w, h), 0)
    sd = ImageDraw.Draw(side)
    for x in range(w):
        t = min(x, w - 1 - x) / 90
        sd.line([(x, 0), (x, h)], fill=int(255 * min(1, t)))
    alpha = ImageChops.multiply(img.getchannel("A"), ImageChops.multiply(fade, side))
    img.putalpha(alpha)
    save(img, "terrain")



# Route overlay: 660 x 270, the route starts at (330, 240) = tip of the nav cursor
# and its last part points the same way as the turn arrow.
ROUTE_START = (330, 240)
ROUTES = {
    "straight": [(330, 240), (330, 200), (326, 150), (334, 100), (330, 60), (330, 34)],
    "right": [(330, 240), (330, 200), (330, 160), (338, 124), (372, 94), (430, 72), (500, 58)],
    "slight_right": [(330, 240), (330, 200), (332, 160), (346, 120), (378, 84), (410, 50)],
    "sharp_right": [(330, 240), (330, 200), (330, 150), (344, 118), (392, 116), (440, 140), (480, 170)],
    "uturn_right": [(330, 240), (330, 200), (332, 140), (350, 104), (390, 100), (410, 130), (412, 180), (412, 220)],
    "roundabout": [(330, 240), (330, 200), (330, 166), (349, 122), (390, 90), (440, 72), (500, 60)],
    "destination": [(330, 240), (330, 200), (328, 160), (332, 130)],
}


def smooth(points, steps=12):
    """Catmull-Rom through the points."""
    pts = [points[0]] + points + [points[-1]]
    out = []
    for i in range(1, len(pts) - 2):
        p0, p1, p2, p3 = pts[i - 1], pts[i], pts[i + 1], pts[i + 2]
        for k in range(steps):
            t = k / steps
            out.append(tuple(0.5 * ((2 * p1[j]) + (-p0[j] + p2[j]) * t + (2 * p0[j] - 5 * p1[j] + 4 * p2[j] - p3[j]) * t * t
                                    + (-p0[j] + 3 * p1[j] - 3 * p2[j] + p3[j]) * t ** 3) for j in range(2)))
    out.append(points[-1])
    return out


def draw_route(points):
    w, h = 660, 270
    img, d = canvas(w, h)
    path = smooth(points, steps=24)
    groups = []
    for p in path:
        depth = max(0.0, min(1.0, (p[1] - 30) / (ROUTE_START[1] - 30)))
        width = int(round((1.4 + 2.2 * depth) * SS))
        if groups and groups[-1][0] == width:
            groups[-1][1].append(p)
        else:
            groups.append((width, [groups[-1][1][-1]] if groups else [], ))
            groups[-1][1].append(p)
    for width, pts in groups:
        if len(pts) > 1:
            d.line(sc(pts), fill=WHITE, width=width, joint="curve")
    if points is ROUTES.get("roundabout") or points == ROUTES["roundabout"]:
        cx, cy, r = 340, 140, 22
        d.ellipse(sc([(cx - r, cy - r), (cx + r, cy + r)]), outline=WHITE, width=int(2.4 * SS))
    # destination pin at the end of the route
    ex, ey = points[-1]
    d.ellipse(sc([(ex - 9, ey - 3), (ex + 9, ey + 3)]), outline=WHITE, width=int(1.2 * SS))
    d.polygon(sc([(ex - 5, ey - 16), (ex + 5, ey - 16), (ex, ey - 2)]), fill=WHITE)
    d.ellipse(sc([(ex - 6, ey - 26), (ex + 6, ey - 14)]), fill=WHITE)
    d.ellipse(sc([(ex - 2.4, ey - 22.4), (ex + 2.4, ey - 17.6)]), fill=(0, 0, 0, 0))
    return img.resize((w, h), Image.LANCZOS)


# Hexagon view map (frame_086): terrain and a smaller route, clipped to the inside of the frame.
HEX_MAP_BOX = (700, 40, 1195, 345)
HEX_MAP_CURSOR_TIP = (993, 280)
HEX_ROUTE_SCALE = 0.62


def hex_map_mask():
    x0, y0, x1, y1 = HEX_MAP_BOX
    body = Image.new("L", (W, H), 0)
    ImageDraw.Draw(body).polygon(ride_body_polygon(), fill=255)
    inner = body.filter(ImageFilter.MinFilter(25)).filter(ImageFilter.GaussianBlur(10))
    left = Image.new("L", (W, H), 0)
    ld = ImageDraw.Draw(left)
    for x in range(x0, x0 + 90):
        ld.line([(x, 0), (x, H)], fill=int(255 * (x - x0) / 90))
    ld.rectangle([x0 + 90, 0, W, H], fill=255)
    top = vertical_ramp(y0, y0 + 40, 0, 255)
    return ImageChops.multiply(ImageChops.multiply(inner, left), top).crop(HEX_MAP_BOX)


def make_hex_map():
    mask = hex_map_mask()
    x0, y0, x1, y1 = HEX_MAP_BOX
    terrain = Image.open(os.path.join(OUT, "terrain.png")).getchannel("A")
    layer = Image.new("L", (W, H), 0)
    layer.paste(terrain, (HEX_MAP_CURSOR_TIP[0] - 330 - 40, y0 - 10))
    save(alpha_image(ImageChops.multiply(layer.crop(HEX_MAP_BOX), mask)), "hex_terrain")
    for f in sorted(os.listdir(OUT)):
        if not (f.startswith("route_") and f.endswith(".png")):
            continue
        route = Image.open(os.path.join(OUT, f)).getchannel("A")
        rw, rh = route.size
        small = route.resize((int(rw * HEX_ROUTE_SCALE), int(rh * HEX_ROUTE_SCALE)), Image.LANCZOS)
        full = Image.new("L", (W, H), 0)
        tip_x = HEX_MAP_CURSOR_TIP[0] - int(ROUTE_START[0] * HEX_ROUTE_SCALE)
        tip_y = HEX_MAP_CURSOR_TIP[1] - int(ROUTE_START[1] * HEX_ROUTE_SCALE)
        full.paste(small, (tip_x, tip_y))
        save(alpha_image(ImageChops.multiply(full.crop(HEX_MAP_BOX), mask.point(lambda v: min(255, v * 2)))), "hex" + f[:-4])


def make_routes():
    for name, pts in ROUTES.items():
        save(draw_route(pts), "route_" + name)
        if name.endswith("right"):
            mirrored = [(2 * ROUTE_START[0] - x, y) for x, y in pts]
            save(draw_route(mirrored), "route_" + name.replace("right", "left"))
    old = os.path.join(OUT, "route.png")
    if os.path.exists(old):
        os.remove(old)


def make_cursor():
    w, h = 48, 30
    img, d = canvas(w, h)
    d.polygon(sc([(24, 0), (48, 26), (24, 20), (0, 26)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "nav_cursor")
    # smaller cursor for the hex view map (frame_086: 34 x 20)
    w, h = 34, 20
    img, d = canvas(w, h)
    d.polygon(sc([(17, 0), (34, 18), (17, 13), (0, 18)]), fill=WHITE)
    save(img.resize((w, h), Image.LANCZOS), "nav_cursor_small")


def make_orbit():
    w, h = 250, 44
    img, d = canvas(w, h)
    d.arc(sc([(2, 2), (w - 2, h - 2)]), 0, 360, fill=WHITE, width=int(1.6 * SS))
    save(img.resize((w, h), Image.LANCZOS), "orbit")


def make_progress_glow():
    w, h = 470, 40
    img = Image.new("L", (w, h), 0)
    ImageDraw.Draw(img).rounded_rectangle([12, 13, w - 12, 27], radius=7, fill=255)
    img = img.filter(ImageFilter.GaussianBlur(6))
    layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    layer.putalpha(img)
    save(layer, "progress_glow")


def make_red_floor():
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).polygon(SHELL, fill=255)
    grad = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(grad)
    for y in range(H):
        t = max(0.0, (y - 300) / 177)
        gd.line([(0, y), (W, y)], fill=int(255 * t ** 1.4))
    alpha = ImageChops.multiply(mask, grad)
    layer = Image.new("RGBA", (W, H), (255, 255, 255, 0))
    layer.putalpha(alpha)
    save(layer, "floor_glow")


def main():
    make_shell()
    make_backing()
    make_glows()
    geo_l, geo_r = make_segments()
    write_bar_qml("PowerBar", geo_l, "l", "Left AMP bar")
    write_bar_qml("RpmBar", geo_r, "r", "Right RPM bar")
    make_trapezoids()
    pointed_bar(190, 12, True, "bar_pointed_left")
    pointed_bar(194, 12, False, "bar_pointed_right")
    make_ruler()
    make_card_shapes()
    make_alert_cards()
    make_terrain()
    make_routes()
    make_hex_map()
    make_cursor()
    make_orbit()
    make_progress_glow()
    make_red_floor()
    labels = extra_main()
    print("cluster art written to", OUT)
    print("hex label centres", [(round(x), round(y)) for x, y in labels])


# ------------------------------------------------------------- bike artwork
def vgrad(size, top, bottom):
    w, h = size
    g = Image.new("RGBA", size)
    gd = ImageDraw.Draw(g)
    for y in range(h):
        t = y / max(1, h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3)) + (255,)
        gd.line([(0, y), (w, y)], fill=c)
    return g


def shape_fill(base, polygon, top, bottom, scale):
    mask = Image.new("L", base.size, 0)
    ImageDraw.Draw(mask).polygon([(x * scale, y * scale) for x, y in polygon], fill=255)
    layer = vgrad(base.size, top, bottom)
    base.paste(layer, (0, 0), mask)
    return mask


def wheel(base, cx, cy, r, scale, masks=None):
    d = ImageDraw.Draw(base)
    s = scale
    d.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s], fill=(34, 36, 38, 255))
    d.ellipse([(cx - r * 0.72) * s, (cy - r * 0.72) * s, (cx + r * 0.72) * s, (cy + r * 0.72) * s], fill=(150, 154, 156, 255))
    d.ellipse([(cx - r * 0.62) * s, (cy - r * 0.62) * s, (cx + r * 0.62) * s, (cy + r * 0.62) * s], fill=(58, 60, 62, 255))
    for k in range(10):
        a = math.radians(k * 36)
        d.line([(cx + math.cos(a) * r * 0.15) * s, (cy + math.sin(a) * r * 0.15) * s,
                (cx + math.cos(a + 0.35) * r * 0.62) * s, (cy + math.sin(a + 0.35) * r * 0.62) * s],
               fill=(170, 174, 176, 255), width=int(1.6 * s))
    d.ellipse([(cx - r * 0.18) * s, (cy - r * 0.18) * s, (cx + r * 0.18) * s, (cy + r * 0.18) * s], fill=(200, 204, 206, 255))
    if masks is not None:
        md = ImageDraw.Draw(masks)
        md.ellipse([(cx - r) * s, (cy - r) * s, (cx + r) * s, (cy + r) * s], fill=255)


# Your own bike render (any size, transparent background). Kept outside assets/cluster
# so the big source file is not packed into the firmware.
BIKE_PHOTO = os.path.join(ROOT, "assets", "source", "bike.png")
BIKE_SIZES = (110, 180, 200, 260)
# Regions on the source photo, as fractions of its width / height
BIKE_REAR_WHEEL = (0.08, 0.42, 0.28, 0.72)
BIKE_REAR_PART = 0.40


def make_bike_from_photo():
    src = Image.open(BIKE_PHOTO).convert("RGBA")
    sw, sh = src.size
    alpha = src.getchannel("A")
    wheel_mask = Image.new("L", src.size, 0)
    x0, y0, x1, y1 = BIKE_REAR_WHEEL
    ImageDraw.Draw(wheel_mask).ellipse([x0 * sw, y0 * sh, x1 * sw, y1 * sh], fill=255)
    wheel_mask = ImageChops.multiply(wheel_mask, alpha)
    rear_mask = Image.new("L", src.size, 0)
    ImageDraw.Draw(rear_mask).rectangle([0, 0.24 * sh, BIKE_REAR_PART * sw, sh], fill=255)
    rear_mask = ImageChops.multiply(rear_mask, alpha)
    box = alpha.point(lambda v: 255 if v > 12 else 0).getbbox()
    parts = {"": src.crop(box), "_wheel": wheel_mask.crop(box), "_rear": rear_mask.crop(box)}
    bw, bh = parts[""].size
    for ow in BIKE_SIZES:
        oh = ow * 3 // 4
        k = min(ow / bw, oh / bh)
        tw, th = max(1, round(bw * k)), max(1, round(bh * k))
        ox, oy = (ow - tw) // 2, (oh - th) // 2
        for suffix, img in parts.items():
            small = img.resize((tw, th), Image.LANCZOS)
            if suffix:
                layer = Image.new("RGBA", (ow, oh), (255, 255, 255, 0))
                a = Image.new("L", (ow, oh), 0)
                a.paste(small, (ox, oy))
                layer.putalpha(a)
            else:
                layer = Image.new("RGBA", (ow, oh), (0, 0, 0, 0))
                layer.paste(small, (ox, oy))
            save(layer, f"bike_{ow}{suffix}")


def make_bike_side():
    w, h, s = 260, 130, 4
    base = Image.new("RGBA", (w * s, h * s), (0, 0, 0, 0))
    rear_wheel = Image.new("L", base.size, 0)
    rear_part = Image.new("L", base.size, 0)
    d = ImageDraw.Draw(base)
    # shadow
    d.ellipse([30 * s, 116 * s, 230 * s, 128 * s], fill=(0, 0, 0, 120))
    wheel(base, 58, 96, 30, s, rear_wheel)
    wheel(base, 206, 96, 30, s)
    # swing arm and fork
    d.line([(58 * s, 96 * s), (112 * s, 82 * s)], fill=(120, 124, 126, 255), width=7 * s)
    d.line([(206 * s, 96 * s), (186 * s, 36 * s)], fill=(160, 164, 166, 255), width=6 * s)
    # main body (monocoque)
    body = [(70, 48), (110, 42), (150, 30), (186, 24), (200, 34), (196, 52), (170, 74), (136, 90), (100, 90), (86, 74)]
    shape_fill(base, body, (236, 238, 240), (150, 154, 158), s)
    # tail
    tail = [(26, 34), (74, 42), (86, 60), (60, 58), (30, 46)]
    m = shape_fill(base, tail, (224, 226, 228), (160, 164, 168), s)
    rear_part.paste(m, (0, 0), m)
    ImageDraw.Draw(rear_part).polygon([(x * s, y * s) for x, y in body[:1] + [(110, 42), (112, 82), (86, 74)]], fill=255)
    # seat
    shape_fill(base, [(40, 30), (96, 36), (110, 42), (74, 44), (32, 38)], (40, 42, 44), (24, 26, 28), s)
    # side window cut-out
    shape_fill(base, [(128, 44), (164, 36), (176, 42), (150, 64), (126, 66)], (30, 32, 34), (14, 15, 16), s)
    # tank highlight & windshield
    shape_fill(base, [(170, 22), (190, 12), (198, 16), (192, 28)], (70, 74, 78), (30, 32, 34), s)
    d.line([(112 * s, 44 * s), (182 * s, 27 * s)], fill=(255, 255, 255, 170), width=2 * s)
    # headlight + handlebar
    d.line([(186 * s, 22 * s), (178 * s, 12 * s), (194 * s, 10 * s)], fill=(60, 62, 64, 255), width=3 * s)
    d.polygon([(198 * s, 34 * s), (206 * s, 36 * s), (200 * s, 44 * s)], fill=(250, 250, 250, 255))
    if os.path.exists(BIKE_PHOTO):
        make_bike_from_photo()
        return
    for ow in (110, 180, 200, 260):
        oh = ow // 2
        save(base.resize((ow, oh), Image.LANCZOS), f"bike_{ow}")
        for name, mask in (("wheel", rear_wheel), ("rear", ImageChops.lighter(rear_part, rear_wheel))):
            layer = Image.new("RGBA", (ow, oh), (255, 255, 255, 0))
            layer.putalpha(mask.resize((ow, oh), Image.LANCZOS))
            save(layer, f"bike_{ow}_{name}")


def front_line_parts():
    """Original front-view line art of the bike, split into drawing strokes."""
    parts = []
    # right mirror (viewer's right)
    parts.append([(230, 60), (268, 42), (330, 34), (318, 50), (262, 66), (236, 72)])
    # right handlebar + lever
    parts.append([(236, 72), (250, 84), (296, 84), (322, 90), (320, 100), (286, 102), (262, 100), (246, 108)])
    # right fork leg
    parts.append([(246, 108), (256, 120), (262, 160), (258, 200), (262, 230), (272, 236), (270, 262), (262, 262)])
    # left mirror
    parts.append([(130, 60), (92, 42), (30, 34), (42, 50), (98, 66), (124, 72)])
    # left handlebar + lever
    parts.append([(124, 72), (110, 84), (64, 84), (38, 92), (30, 104), (70, 100), (98, 100), (114, 108)])
    # left fork leg
    parts.append([(114, 108), (104, 120), (98, 160), (102, 200), (98, 230), (88, 236), (90, 262), (98, 262)])
    # screen / top cowl
    parts.append([(124, 72), (130, 58), (150, 42), (180, 38), (210, 42), (230, 58), (236, 72)])
    # nose (V shape around headlight)
    parts.append([(124, 72), (132, 96), (148, 138), (168, 164), (192, 164), (212, 138), (228, 96), (236, 72)])
    return parts


def make_front_line_art():
    w, h, s = 360, 270, 3
    parts = front_line_parts()
    for k, pts in enumerate(parts):
        img = Image.new("L", (w * s, h * s), 0)
        ImageDraw.Draw(img).line([(x * s, y * s) for x, y in pts], fill=255, width=int(3.2 * s), joint="curve")
        a = img.resize((w, h), Image.LANCZOS)
        glow = a.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.6))
        a = ImageChops.lighter(a, glow)
        layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
        layer.putalpha(a)
        save(layer, f"front_line_{k}")
    # headlight
    img = Image.new("L", (w * s, h * s), 0)
    ImageDraw.Draw(img).polygon([(x * s, y * s) for x, y in [(146, 118), (166, 136), (180, 142), (194, 136), (214, 118), (204, 148), (180, 156), (156, 148)]], fill=255)
    a = img.resize((w, h), Image.LANCZOS)
    glow = a.filter(ImageFilter.GaussianBlur(10))
    a = ImageChops.lighter(a, glow)
    layer = Image.new("RGBA", (w, h), (255, 255, 255, 0))
    layer.putalpha(a)
    save(layer, "front_headlight")


# -------------------------------------------------------------- ui artwork
def alpha_layer(mask):
    layer = Image.new("RGBA", mask.size, (255, 255, 255, 0))
    layer.putalpha(mask)
    return layer


def make_fingerprint():
    size, s = 76, 4
    img = Image.new("L", (size * s, size * s), 0)
    d = ImageDraw.Draw(img)
    c = size * s / 2
    for k, r in enumerate(range(6, 34, 5)):
        start = 200 + (k * 23) % 40
        end = 520 - (k * 31) % 60
        d.arc([c - r * s, c - r * s + 4 * s, c + r * s, c + r * s + 4 * s], start, end, fill=255, width=int(2.2 * s))
    save(alpha_layer(img.resize((size, size), Image.LANCZOS)), "fingerprint")
    ring = Image.new("L", (size * s, size * s), 0)
    ImageDraw.Draw(ring).ellipse([2 * s, 2 * s, (size - 2) * s, (size - 2) * s], fill=255)
    save(alpha_layer(ring.resize((size, size), Image.LANCZOS)), "fingerprint_disc")


def make_avatar(size=106):
    # Every coordinate is a fraction of the 106 px drawing, so the smaller
    # avatar is the same picture rather than the same shapes on a smaller ring.
    s = 4
    k = size * s / 106.0
    img = Image.new("L", (size * s, size * s), 0)
    d = ImageDraw.Draw(img)
    stroke = max(1, int(round(3 * k)))
    d.ellipse([3 * k, 3 * k, 103 * k, 103 * k], outline=255, width=stroke)
    d.ellipse([38 * k, 20 * k, 68 * k, 50 * k], outline=255, width=stroke)
    d.rounded_rectangle([24 * k, 62 * k, 82 * k, 88 * k], radius=12 * k,
                        outline=255, width=stroke)
    save(alpha_layer(img.resize((size, size), Image.LANCZOS)), f"avatar_{size}")


def make_shield():
    w, h, s = 200, 230, 3
    img = Image.new("L", (w * s, h * s), 0)
    d = ImageDraw.Draw(img)
    outline = [(100, 0), (196, 30), (192, 120), (160, 184), (100, 228), (40, 184), (8, 120), (4, 30)]
    d.polygon([(x * s, y * s) for x, y in outline], fill=150)
    d.polygon([(x * s, y * s) for x, y in [(100, 28), (170, 50), (100, 50)]], fill=0)
    d.polygon([(x * s, y * s) for x, y in [(100, 120), (168, 120), (140, 170), (100, 200)]], fill=0)
    d.polygon([(x * s, y * s) for x, y in [(30, 50), (100, 28), (100, 120), (30, 120)]], fill=210)
    save(alpha_layer(img.resize((w, h), Image.LANCZOS)), "shield")


def make_seat():
    w, h, s = 260, 70, 3
    base = Image.new("RGBA", (w * s, h * s), (0, 0, 0, 0))
    shape_fill(base, [(4, 12), (160, 6), (170, 20), (170, 44), (120, 56), (30, 50), (6, 30)], (150, 245, 215), (60, 160, 130), s)
    shape_fill(base, [(174, 8), (250, 10), (254, 28), (250, 46), (176, 48)], (130, 230, 200), (60, 150, 120), s)
    img = base.resize((w, h), Image.LANCZOS)
    glow = img.getchannel("A").filter(ImageFilter.GaussianBlur(8)).point(lambda v: int(v * 0.5))
    halo = Image.new("RGBA", (w, h), (111, 255, 216, 0))
    halo.putalpha(glow)
    halo.alpha_composite(img)
    save(halo, "seat")


def make_album_art(size=76):
    # Drawn at the size it is shown at, so the music page does not scale it.
    k = size / 100.0
    img = vgrad((size, size), (210, 214, 216), (120, 124, 128))
    d = ImageDraw.Draw(img)
    for stem in range(5):
        x = (18 + stem * 18) * k
        d.line([(x, 96 * k), (x + 4 * k, (52 - stem * 3) * k)], fill=(60, 60, 64, 255), width=1)
        for a in range(0, 360, 30):
            r = (7 + (stem % 2) * 2) * k
            cx, cy = x + 4 * k, (50 - stem * 3) * k
            d.line([(cx, cy), (cx + math.cos(math.radians(a)) * r, cy + math.sin(math.radians(a)) * r)],
                   fill=(245, 245, 245, 255), width=1)
    save(img, "album_art")


def make_payment_card():
    w, h = 150, 94
    img = vgrad((w, h), (46, 56, 64), (20, 24, 28))
    mask = Image.new("L", (w * 3, h * 3), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, w * 3, h * 3], radius=24, fill=255)
    img.putalpha(mask.resize((w, h), Image.LANCZOS))
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([14, 30, 36, 46], radius=3, fill=(214, 180, 90, 255))
    d.ellipse([88, 10, 150, 72], fill=(111, 255, 216, 60))
    d.ellipse([104, 26, 146, 68], fill=(111, 255, 216, 90))
    for i in range(4):
        d.rectangle([14 + i * 30, 62, 38 + i * 30, 66], fill=(200, 206, 210, 200))
    save(img, "payment_card")


def make_ring(size, width, name):
    s = 4
    img = Image.new("L", (size * s, size * s), 0)
    ImageDraw.Draw(img).ellipse([0, 0, size * s - 1, size * s - 1], outline=255, width=int(width * s))
    save(alpha_layer(img.resize((size, size), Image.LANCZOS)), name)


# Hexagon speedometer measured on frame_086 (screen coordinates)
HEX_CENTER = (645, 208.5)
HEX_OUTER = [(555, 333), (467, 208.5), (555, 84), (735, 84), (823, 208.5), (735, 333)]
HEX_BAND = 40
# band thickness per side (bottom-left, top-left, top, top-right, bottom-right)
HEX_BANDS = [46, 46, 38, 46, 46]
HEX_ORIGIN = (440, 70)          # top-left of the generated hex images
HEX_SIZE = (420, 290)
HEX_NEEDLE = 132
HEX_LABELS = [(536.5, 247.5), (520, 184), (553.5, 139), (619, 110.5), (680, 110.5), (740, 135), (775, 182.5), (767.5, 245)]


def hex_bounds():
    """Segment boundaries as path fractions: every side of the open hexagon is cut in two."""
    lens = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(HEX_OUTER, HEX_OUTER[1:])]
    total = sum(lens)
    out, acc = [0.0], 0.0
    for ln in lens:
        out += [(acc + ln / 2) / total, (acc + ln) / total]
        acc += ln
    return out


def hex_inner_outline():
    """Inner edge of the ring: every side moved inward by its own band thickness."""
    lines = []
    for (a, b), d in zip(zip(HEX_OUTER, HEX_OUTER[1:]), HEX_BANDS):
        ux, uy = unit(a, b)
        nx, ny = -uy, ux
        lines.append(((a[0] + nx * d, a[1] + ny * d), (ux, uy)))

    def cross(l1, l2):
        (p, u), (q, v) = l1, l2
        den = u[0] * v[1] - u[1] * v[0]
        t = ((q[0] - p[0]) * v[1] - (q[1] - p[1]) * v[0]) / den
        return (p[0] + u[0] * t, p[1] + u[1] * t)
    pts = [lines[0][0]]
    for l1, l2 in zip(lines, lines[1:]):
        pts.append(cross(l1, l2))
    (p, u), d = lines[-1], HEX_BANDS[-1]
    end = HEX_OUTER[-1]
    pts.append((end[0] - u[1] * d, end[1] + u[0] * d))
    return pts


def hex_path_point(outline, t):
    """Point at fraction t (0..1) along an open polyline."""
    lens = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(outline, outline[1:])]
    dist = t * sum(lens)
    for (a, b), ln in zip(zip(outline, outline[1:]), lens):
        if dist <= ln:
            return lerp(a, b, dist / ln)
        dist -= ln
    return outline[-1]


def hex_local(points, scale=SS):
    ox, oy = HEX_ORIGIN
    return [((x - ox) * scale, (y - oy) * scale) for x, y in points]


def stroke_local(paths, width):
    w, h = HEX_SIZE
    img = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(img)
    for p in paths:
        d.line(hex_local(p), fill=255, width=max(1, int(width * SS)), joint="curve")
    return img.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.2))


def hex_quad(t0, t1):
    inner = hex_inner_outline()
    outs = [hex_path_point(HEX_OUTER, t0 + (t1 - t0) * k / 24) for k in range(25)]
    ins = [hex_path_point(inner, t0 + (t1 - t0) * k / 24) for k in range(25)]
    return outs + ins[::-1]


def hex_mask(polys):
    w, h = HEX_SIZE
    img = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(img)
    for poly in polys:
        d.polygon(hex_local(poly), fill=255)
    return img.resize((w, h), Image.LANCZOS)


def write_hex_qml(pieces, labels, angles):
    lines = [
        "// Generated by tools/generate_cluster_art.py. Do not edit.",
        "import QtQuick",
        "import QtQuickUltralite.Extras",
        "import ClusterCore",
        "",
        "// Hexagon speedometer: 10 segments (two halves each), labels 0..140 and needle.",
        "Item {",
        "    id: gauge",
        "",
        "    property int speed: 0",
        "    property int clamped: Math.max(0, Math.min(150, speed))",
        "    property int litHalves: Math.round(3 + clamped / 10)",
        "    property color litColor: \"#7DFFDB\"",
        "    property color offColor: \"#3C3C3D\"",
        "    property real needleAngle: " + needle_expression(angles),
        "",
        f"    x: {HEX_ORIGIN[0]}",
        f"    y: {HEX_ORIGIN[1]}",
        f"    width: {HEX_SIZE[0]}",
        f"    height: {HEX_SIZE[1]}",
        "",
    ]
    for k, (px, py) in enumerate(pieces):
        lines += [
            "    ColorizedImage {",
            f"        x: {px}",
            f"        y: {py}",
            f"        source: \"qrc:/assets/cluster/hex_piece{k}.png\"",
            f"        color: gauge.litHalves > {k} ? gauge.litColor : gauge.offColor",
            "    }",
            "",
        ]
    lines += [
        "    ColorizedImage {",
        "        source: \"qrc:/assets/cluster/hex_shade.png\"",
        "        color: \"#000000\"",
        "        opacity: 0.35",
        "    }",
        "",
        "    ColorizedImage {",
        "        source: \"qrc:/assets/cluster/hex_rim.png\"",
        "        color: \"#FFFFFF\"",
        "        opacity: 0.08",
        "    }",
        "",
        "    ColorizedImage {",
        "        source: \"qrc:/assets/cluster/hex_dividers.png\"",
        "        color: \"#0A0B0C\"",
        "    }",
        "",
        "    ColorizedImage {",
        "        source: \"qrc:/assets/cluster/hex_inner.png\"",
        "        color: Theme.hexRing",
        "    }",
        "",
    ]
    for k, (lx, ly) in enumerate(labels):
        lines += [
            "    Text {",
            f"        x: {int(round(lx - HEX_ORIGIN[0])) - 24}",
            f"        y: {int(round(ly - HEX_ORIGIN[1])) - 13}",
            "        width: 48",
            "        horizontalAlignment: Text.AlignHCenter",
            f"        text: \"{k * 20}\"",
            "        color: \"#EEF1F1\"",
            "        font.family: Theme.fontFamily",
            "        font.pixelSize: 18",
            "        font.italic: true",
            "    }",
            "",
        ]
    cx, cy = HEX_CENTER[0] - HEX_ORIGIN[0], HEX_CENTER[1] - HEX_ORIGIN[1]
    lines += [
        "    Rectangle {",
        f"        x: {cx:.1f}",
        f"        y: {cy - 2.5:.1f}",
        f"        width: {HEX_NEEDLE}",
        "        height: 5",
        "        radius: 2.5",
        "        gradient: Gradient {",
        "            orientation: Gradient.Horizontal",
        "            GradientStop { position: 0.0; color: \"#00600010\" }",
        "            GradientStop { position: 0.35; color: \"#B0900018\" }",
        "            GradientStop { position: 1.0; color: \"#E8141E\" }",
        "        }",
        "        transform: Rotation {",
        "            origin.x: 0",
        "            origin.y: 2.5",
        "            angle: gauge.needleAngle",
        "        }",
        "    }",
        "}",
    ]
    with open(os.path.join(QML, "HexGauge.qml"), "w") as f:
        f.write("\n".join(lines) + "\n")


def needle_expression(angles):
    """Piecewise-linear needle angle, one step per 20 km/h."""
    expr = f"{angles[-1]:.1f}"
    for k in range(len(angles) - 2, -1, -1):
        a0, a1 = angles[k], angles[k + 1]
        expr = (f"(clamped < {(k + 1) * 20} ? {a0:.1f} + (clamped - {k * 20}) * {(a1 - a0) / 20:.3f} : {expr})")
    return expr


def make_hex_gauge():
    """10 segments along the open hexagon; each is cut in two halves for a finer fill."""
    bounds = hex_bounds()
    segs = len(bounds) - 1
    pieces = []
    for k in range(segs * 2):
        a, b = bounds[k // 2], bounds[k // 2 + 1]
        t0 = a + (b - a) * (k % 2) / 2
        t1 = a + (b - a) * (k % 2 + 1) / 2
        mask = hex_mask([hex_quad(max(0, t0 - 0.002), min(1, t1 + 0.002))])
        x0, y0, x1, y1 = mask.getbbox()
        save(alpha_layer(mask.crop((x0, y0, x1, y1))), f"hex_piece{k}")
        pieces.append((x0, y0))
    for k in range(segs * 2, 40):
        old = os.path.join(OUT, f"hex_piece{k}.png")
        if os.path.exists(old):
            os.remove(old)
    for k in range(8):
        old = os.path.join(OUT, f"hex_seg{k}.png")
        if os.path.exists(old):
            os.remove(old)

    ring = hex_mask([hex_quad(0, 1)])
    w, h = HEX_SIZE
    shade = Image.new("L", (w * SS, h * SS), 0)
    sd = ImageDraw.Draw(shade)
    steps = 24
    inner_line = hex_inner_outline()
    for i in range(steps):
        t = i / (steps - 1)
        path = [lerp(o, n, t) for o, n in zip(HEX_OUTER, inner_line)]
        sd.line(hex_local(path), fill=int(255 * t ** 1.2), width=int(3 * SS), joint="curve")
    shade = shade.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.5))
    save(alpha_layer(ImageChops.multiply(ring, shade)), "hex_shade")
    # thin bright line just inside the outer edge (the light catches the outer rim)
    rim = stroke_local([[lerp(o, n, 0.12) for o, n in zip(HEX_OUTER, inner_line)]], 2.0)
    save(alpha_layer(ImageChops.multiply(rim, ring)), "hex_rim")

    div = Image.new("L", (w * SS, h * SS), 0)
    dd = ImageDraw.Draw(div)
    inner = hex_inner_outline()
    for k in range(1, segs):
        a = hex_path_point(HEX_OUTER, bounds[k])
        b = hex_path_point(inner, bounds[k])
        dd.line(hex_local([lerp(a, b, -0.1), lerp(a, b, 1.1)]), fill=255, width=int(2 * SS))
    save(alpha_layer(ImageChops.multiply(div.resize((w, h), Image.LANCZOS), ring.filter(ImageFilter.MaxFilter(3)))), "hex_dividers")

    # inner hexagon: thin outline, soft band with ticks
    cx, cy = HEX_CENTER
    img = Image.new("L", (w * SS, h * SS), 0)
    d = ImageDraw.Draw(img)

    def hexagon(rx, ry):
        return [(cx - rx, cy), (cx - rx / 2, cy - ry), (cx + rx / 2, cy - ry), (cx + rx, cy), (cx + rx / 2, cy + ry), (cx - rx / 2, cy + ry)]
    outline = hex_local(hexagon(79, 55))
    d.line(outline + [outline[0]], fill=200, width=int(1.5 * SS))
    band_img = Image.new("L", (w * SS, h * SS), 0)
    band = hex_local(hexagon(61, 43.5))
    ImageDraw.Draw(band_img).line(band + [band[0]], fill=90, width=int(7 * SS), joint="curve")
    band_img = band_img.resize((w, h), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1.5))
    ticks = hexagon(61, 43.5)
    for i in range(6):
        a, b = ticks[i], ticks[(i + 1) % 6]
        for t in (0.0, 0.5):
            p = lerp(a, b, t)
            q = lerp(p, (cx, cy), 0.1)
            d.line(hex_local([lerp(p, (cx, cy), -0.03), q]), fill=150, width=int(1.3 * SS))
    a = ImageChops.lighter(img.resize((w, h), Image.LANCZOS), band_img)
    save(alpha_layer(ImageChops.lighter(a, a.filter(ImageFilter.GaussianBlur(3)).point(lambda v: int(v * 0.8)))), "hex_inner")

    # backdrop panel behind the gauge: rounded hexagon, lighter rim
    back = [(440, 80), (850, 80), (902, 168), (814, 341), (476, 341), (388, 168)]
    bw, bh = W, H
    mask = Image.new("L", (bw * SS, bh * SS), 0)
    ImageDraw.Draw(mask).polygon(sc(rounded(back + [back[0], back[1]], [0, 34, 34, 30, 30, 30, 34, 0])), fill=255)
    mask = mask.resize((bw, bh), Image.LANCZOS).filter(ImageFilter.GaussianBlur(1))
    # the inside of the ring (and the open bottom with the speed) stays black
    hole = Image.new("L", (bw * SS, bh * SS), 0)
    inner_pts = hex_inner_outline()
    ImageDraw.Draw(hole).polygon(sc(inner_pts + [(inner_pts[-1][0], 360), (inner_pts[0][0], 360)]), fill=255)
    hole = hole.resize((bw, bh), Image.LANCZOS).filter(ImageFilter.GaussianBlur(2))
    fill = ImageChops.subtract(mask, hole)
    save(alpha_layer(fill.crop((380, 76, 912, 352))), "hex_backdrop")

    labels = HEX_LABELS
    angles = []
    for px, py in labels:
        a = math.degrees(math.atan2(py - cy, px - cx))
        while angles and a < angles[-1]:
            a += 360
        angles.append(a)
    write_hex_qml(pieces, labels, angles)
    return labels


def make_battery_tall():
    band = band_mask()
    cut = Image.new("L", band.size, 0)
    top_outer, top_inner = (117.5, 147.5), (140.0, 106.5)
    ImageDraw.Draw(cut).polygon(half_plane_region(top_outer, top_inner, BAR_KNEE), fill=255)
    end = Image.new("L", band.size, 0)
    ImageDraw.Draw(end).polygon(half_plane_region(BAR_CUTS[0][0], BAR_CUTS[0][1], BAR_KNEE), fill=255)
    mask = ImageChops.multiply(ImageChops.multiply(band, cut), end).resize((W, H), Image.LANCZOS)
    save(alpha_layer(mask), "battery_tall")
    # glossy stripe along the bar
    stripe = ImageChops.multiply(mask, offset_band(-6, 8))
    save(alpha_layer(stripe), "battery_tall_gloss")
    # thin lines beside the column (hex view): outer and inner edge
    outer = ImageChops.multiply(stroke([offset_path(bar_centre(extend_top=10, extend_end=20), BAR_WIDTH / 2 + 7)], 1.3),
                                vertical_ramp(105, 135, 0, 255))
    inner = ImageChops.multiply(stroke([offset_path(bar_centre(extend_top=10, extend_end=20), -(BAR_WIDTH / 2 + 7))], 1.2),
                                vertical_ramp(95, 125, 0, 255))
    save(alpha_layer(outer), "battery_edge_outer")
    save(alpha_layer(inner), "battery_edge_inner")
    make_battery_slices(mask)


BATTERY_SLICES = 20


def cut_at(f):
    """Slanted cut line at fraction f (0 = bottom end, 1 = top cut) of the bar."""
    mids = [lerp(o, n, 0.5) for o, n in BAR_CUTS]
    lens = [math.hypot(b[0] - a[0], b[1] - a[1]) for a, b in zip(mids, mids[1:])]
    dist = f * sum(lens)
    i = 0
    while i < len(lens) - 1 and dist > lens[i]:
        dist -= lens[i]
        i += 1
    t = min(1.0, dist / lens[i])
    (oa, ia), (ob, ib) = BAR_CUTS[i], BAR_CUTS[i + 1]
    return lerp(oa, ob, t), lerp(ia, ib, t)


def make_battery_slices(column):
    geo = []
    big = column.resize((W * SS, H * SS), Image.LANCZOS)
    for k in range(BATTERY_SLICES):
        (o0, i0), (o1, i1) = cut_at(k / BATTERY_SLICES), cut_at((k + 1) / BATTERY_SLICES)
        mid = lerp(lerp(o0, i0, 0.5), lerp(o1, i1, 0.5), 0.5)
        # overlap the next slice by 1.5 px so no seam shows between lit slices
        ux, uy = unit(lerp(o0, i0, 0.5), lerp(o1, i1, 0.5))
        o1, i1 = (o1[0] + ux * 1.5, o1[1] + uy * 1.5), (i1[0] + ux * 1.5, i1[1] + uy * 1.5)
        r1 = Image.new("L", big.size, 0)
        ImageDraw.Draw(r1).polygon(half_plane_region(o0, i0, mid), fill=255)
        r2 = Image.new("L", big.size, 0)
        if k == BATTERY_SLICES - 1:
            r2.paste(255, (0, 0) + big.size)
        else:
            ImageDraw.Draw(r2).polygon(half_plane_region(o1, i1, mid), fill=255)
        if k == 0:
            r1.paste(255, (0, 0) + big.size)
        m = ImageChops.multiply(ImageChops.multiply(big, r1), r2).resize((W, H), Image.LANCZOS)
        box = m.getbbox()
        if not box:
            continue
        save(alpha_layer(m.crop(box)), f"battery_slice{k}")
        geo.append((k, box[0], box[1]))
    lines = [
        "// Generated by tools/generate_cluster_art.py. Do not edit.",
        "import QtQuick",
        "import QtQuickUltralite.Extras",
        "",
        f"// Tall battery column (hex view): {BATTERY_SLICES} slanted slices, slice 0 at the bottom.",
        "Item {",
        "    id: column",
        "",
        "    property int percent: 0",
        f"    property int litCount: Math.round(Math.max(0, Math.min(100, percent)) * {BATTERY_SLICES} / 100)",
        "    property color litColor: \"#78F0C8\"",
        "    property color offColor: \"#7E9E93\"",
        "",
        "    width: 1280",
        "    height: 480",
        "",
        "    ColorizedImage {",
        "        source: \"qrc:/assets/cluster/battery_tall.png\"",
        "        color: column.offColor",
        "    }",
        "",
    ]
    for k, x, y in geo:
        lines += [
            "    ColorizedImage {",
            f"        x: {x}",
            f"        y: {y}",
            f"        source: \"qrc:/assets/cluster/battery_slice{k}.png\"",
            f"        visible: column.litCount > {k}",
            "        color: column.litColor",
            "    }",
            "",
        ]
    lines[-1] = "}"
    with open(os.path.join(QML, "BatteryColumn.qml"), "w") as f:
        f.write("\n".join(lines) + "\n")


def offset_band(offset, width):
    c = offset_path(bar_centre(), offset)
    img = Image.new("L", (W, H), 0)
    ImageDraw.Draw(img).line(c, fill=255, width=width, joint="curve")
    return img.filter(ImageFilter.GaussianBlur(3))


def extra_main():
    make_bike_side()
    make_front_line_art()
    make_fingerprint()
    make_avatar(106)
    make_avatar(92)
    make_shield()
    make_seat()
    make_album_art()
    make_payment_card()
    make_ring(190, 16, "ring190")
    labels = make_hex_gauge()
    make_battery_tall()
    return labels


if __name__ == "__main__":
    main()
