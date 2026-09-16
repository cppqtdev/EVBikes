#!/usr/bin/env python3
"""Generates white-on-transparent PNG icons and frame images for the cluster.

White artwork is tinted at runtime with ColorizedImage, so one file serves every
theme colour. Run: python3 tools/generate_assets.py  (needs Pillow)
"""
import math
import os
import re
import shutil

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ICONS = os.path.join(ROOT, "assets", "icons")
TURNS = os.path.join(ROOT, "assets", "turns")
IMAGES = os.path.join(ROOT, "assets", "images")
SS = 4
W = (255, 255, 255, 255)


def canvas(size):
    img = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    return img, ImageDraw.Draw(img)


def save(img, size, folder, name):
    os.makedirs(folder, exist_ok=True)
    img.resize((size, size), Image.LANCZOS).save(os.path.join(folder, name + ".png"))


def s(v):
    return v * SS


def pts(points):
    return [(s(x), s(y)) for x, y in points]


def line(d, points, width):
    d.line(pts(points), fill=W, width=int(s(width)), joint="curve")
    r = s(width) / 2
    for x, y in (points[0], points[-1]):
        d.ellipse([s(x) - r, s(y) - r, s(x) + r, s(y) + r], fill=W)


def arc(d, box, start, end, width):
    d.arc([s(v) for v in box], start, end, fill=W, width=int(s(width)))


def head(d, tip, angle_deg, size):
    a = math.radians(angle_deg)
    left = (tip[0] - size * math.cos(a - 0.55), tip[1] - size * math.sin(a - 0.55))
    right = (tip[0] - size * math.cos(a + 0.55), tip[1] - size * math.sin(a + 0.55))
    d.polygon(pts([tip, left, right]), fill=W)


# ---------------------------------------------------------------- icons 48px
def icon_indicator(d, left):
    if left:
        d.polygon(pts([(6, 24), (22, 10), (22, 18), (42, 18), (42, 30), (22, 30), (22, 38)]), fill=W)
    else:
        d.polygon(pts([(42, 24), (26, 10), (26, 18), (6, 18), (6, 30), (26, 30), (26, 38)]), fill=W)


def icon_beam(d, high):
    d.chord([s(20), s(10), s(44), s(38)], 90, 270, fill=W)
    d.rectangle([s(31), s(10), s(33), s(38)], fill=(0, 0, 0, 0))
    d.chord([s(22), s(12), s(42), s(36)], 90, 270, fill=(0, 0, 0, 0))
    arc(d, (20, 10, 44, 38), 270, 90, 3)
    d.line(pts([(32, 10), (32, 38)]), fill=W, width=int(s(3)))
    for i, y in enumerate((14, 20, 26, 32) if high else (16, 22, 28, 34)):
        y2 = y if high else y + 4
        line(d, [(4, y2), (16, y)], 3)


def icon_abs(d):
    arc(d, (4, 6, 44, 42), 0, 360, 3)
    arc(d, (0, 4, 48, 44), 120, 240, 3)
    arc(d, (0, 4, 48, 44), -60, 60, 3)
    y = 24
    line(d, [(13, 30), (16, 18), (19, 30)], 2.5)
    line(d, [(14, 26), (18, 26)], 2)
    line(d, [(22, 18), (22, 30)], 2.5)
    arc(d, (20, 18, 27, 24), 270, 90, 2.5)
    arc(d, (20, 24, 28, 30), 270, 90, 2.5)
    arc(d, (29, 18, 36, 24), 90, 330, 2.5)
    arc(d, (29, 24, 36, 30), 270, 150, 2.5)
    del y


def icon_warning(d):
    arc(d, (4, 4, 44, 44), 0, 360, 3.5)
    line(d, [(24, 13), (24, 28)], 4)
    d.ellipse([s(21.5), s(32), s(26.5), s(37)], fill=W)


def icon_battery(d):
    d.rounded_rectangle([s(6), s(14), s(42), s(40)], radius=s(3), outline=W, width=int(s(3)))
    d.rectangle([s(11), s(9), s(17), s(14)], fill=W)
    d.rectangle([s(31), s(9), s(37), s(14)], fill=W)
    line(d, [(11, 27), (19, 27)], 3)
    line(d, [(29, 27), (37, 27)], 3)
    line(d, [(33, 23), (33, 31)], 3)


def icon_temp(d):
    d.rounded_rectangle([s(18), s(4), s(26), s(30)], radius=s(4), outline=W, width=int(s(3)))
    d.ellipse([s(14), s(28), s(30), s(44)], fill=W)
    line(d, [(22, 12), (22, 32)], 3)
    for y in (10, 16, 22):
        line(d, [(30, y), (38, y)], 2.5)


def icon_bluetooth(d):
    line(d, [(14, 15), (32, 32), (24, 40), (24, 8), (32, 16), (14, 33)], 3)


def icon_settings(d):
    cx, cy = 24, 24
    for i in range(8):
        a = math.radians(i * 45)
        x, y = cx + 15 * math.cos(a), cy + 15 * math.sin(a)
        d.ellipse([s(x - 5), s(y - 5), s(x + 5), s(y + 5)], fill=W)
    d.ellipse([s(10), s(10), s(38), s(38)], fill=W)
    d.ellipse([s(18), s(18), s(30), s(30)], fill=(0, 0, 0, 0))


def icon_bell(d, muted):
    d.chord([s(12), s(8), s(36), s(40)], 180, 360, fill=W)
    d.rectangle([s(12), s(23), s(36), s(34)], fill=W)
    d.rectangle([s(8), s(33), s(40), s(36)], fill=W)
    d.ellipse([s(20), s(36), s(28), s(44)], fill=W)
    if muted:
        d.line(pts([(6, 42), (42, 6)]), fill=(0, 0, 0, 0), width=int(s(8)))
        line(d, [(8, 40), (40, 8)], 3)


def icon_charging(d):
    d.polygon(pts([(28, 4), (12, 27), (22, 27), (18, 44), (36, 20), (26, 20)]), fill=W)


def icon_side_stand(d):
    arc(d, (4, 10, 20, 26), 0, 360, 3)
    arc(d, (28, 10, 44, 26), 0, 360, 3)
    line(d, [(12, 18), (22, 10), (36, 18)], 3)
    line(d, [(24, 20), (30, 40)], 4)
    line(d, [(24, 42), (38, 42)], 3)


def icon_tyre(d):
    arc(d, (6, 6, 42, 42), 0, 360, 4)
    arc(d, (15, 15, 33, 33), 0, 360, 3)
    d.polygon(pts([(24, 17), (22, 26), (26, 26)]), fill=W)
    d.ellipse([s(22.5), s(28), s(25.5), s(31)], fill=W)


def icon_sos(d):
    d.rounded_rectangle([s(3), s(12), s(45), s(36)], radius=s(6), outline=W, width=int(s(3)))
    arc(d, (9, 17, 17, 24), 90, 330, 2.5)
    arc(d, (9, 24, 17, 31), 270, 150, 2.5)
    arc(d, (20, 17, 28, 31), 0, 360, 2.5)
    arc(d, (31, 17, 39, 24), 90, 330, 2.5)
    arc(d, (31, 24, 39, 31), 270, 150, 2.5)


def icon_phone(d):
    d.polygon(pts([(10, 6), (18, 6), (21, 16), (16, 20), (28, 32), (32, 27), (42, 30), (42, 38),
                   (36, 43), (28, 42), (6, 20), (5, 12)]), fill=W)


def icon_music(d):
    line(d, [(18, 36), (18, 10), (40, 6), (40, 32)], 3.5)
    d.ellipse([s(8), s(30), s(20), s(42)], fill=W)
    d.ellipse([s(30), s(26), s(42), s(38)], fill=W)


def icon_nav(d):
    d.polygon(pts([(24, 4), (40, 44), (24, 34), (8, 44)]), fill=W)


def icon_signal(d):
    for i in range(4):
        x = 8 + i * 9
        d.rectangle([s(x), s(40 - (i + 1) * 8), s(x + 6), s(40)], fill=W)


def icon_signal_full(d):
    d.polygon(pts([(4, 44), (44, 44), (44, 4)]), fill=W)


def icon_lock(d):
    d.rounded_rectangle([s(10), s(20), s(38), s(44)], radius=s(4), fill=W)
    arc(d, (15, 4, 33, 30), 180, 360, 4)
    line(d, [(15, 17), (15, 21)], 4)
    line(d, [(33, 17), (33, 21)], 4)


def icon_play(d):
    d.polygon(pts([(14, 8), (40, 24), (14, 40)]), fill=W)


def icon_pause(d):
    d.rectangle([s(12), s(8), s(20), s(40)], fill=W)
    d.rectangle([s(28), s(8), s(36), s(40)], fill=W)


def icon_next(d, reverse=False):
    p = [(8, 8), (28, 24), (8, 40)]
    bar = [s(32), s(8), s(38), s(40)]
    if reverse:
        p = [(48 - x, y) for x, y in p]
        bar = [s(10), s(8), s(16), s(40)]
    d.polygon(pts(p), fill=W)
    d.rectangle(bar, fill=W)


def icon_leaf(d):
    d.chord([s(6), s(4), s(46), s(44)], 90, 270, fill=W)
    d.chord([s(-14), s(4), s(26), s(44)], 270, 90, fill=W)
    line(d, [(10, 42), (34, 12)], 2.5)


def icon_check(d):
    line(d, [(8, 25), (19, 36), (40, 12)], 5)


def icon_back(d):
    line(d, [(30, 8), (14, 24), (30, 40)], 5)


def icon_chevron(d):
    line(d, [(18, 8), (34, 24), (18, 40)], 5)


# Thin-line telltales matching the reference housing (frame_020 / frame_046)
TT = 2.2


def tt_chevron(d, left):
    for dx in (0, 6):
        if left:
            line(d, [(28 + dx, 6), (12 + dx, 24), (28 + dx, 42)], TT)
        else:
            line(d, [(20 - dx, 6), (36 - dx, 24), (20 - dx, 42)], TT)


def tt_beam(d, high):
    arc(d, (12, 12, 44, 36), 270, 90, TT)
    line(d, [(28, 12), (22, 12), (22, 36), (28, 36)], TT)
    for i in range(4):
        y = 15 + i * 6
        if high:
            line(d, [(3, y), (16, y)], TT)
        else:
            line(d, [(3, y + 3), (16, y - 1)], TT)


def tt_warning(d):
    arc(d, (5, 5, 43, 43), 0, 360, TT)
    line(d, [(24, 13), (24, 28)], 3.4)
    d.ellipse([s(22), s(32), s(26), s(36)], fill=W)


def tt_abs(d):
    arc(d, (7, 7, 41, 41), 0, 360, 2.6)
    arc(d, (2, 3, 46, 45), 125, 235, TT)
    arc(d, (2, 3, 46, 45), -55, 55, TT)
    font = ImageFont.truetype(os.path.join(ROOT, "assets", "fonts", "Inter-Bold.ttf"), s(10.5))
    d.text((s(24), s(24.5)), "ABS", font=font, fill=W, anchor="mm")


def tt_battery(d):
    d.rectangle([s(3), s(13), s(35), s(40)], outline=W, width=int(s(TT)))
    d.rectangle([s(8), s(8), s(14), s(13)], outline=W, width=int(s(TT * 0.8)))
    d.rectangle([s(24), s(8), s(30), s(13)], outline=W, width=int(s(TT * 0.8)))
    line(d, [(8, 27), (14, 27)], TT)
    line(d, [(20, 27), (29, 27)], TT)
    line(d, [(24.5, 22.5), (24.5, 31.5)], TT)
    line(d, [(42, 16), (42, 29)], 3.2)
    d.ellipse([s(40.2), s(33), s(43.8), s(36.6)], fill=W)


def icon_sun(d):
    d.ellipse([s(14), s(14), s(34), s(34)], fill=W)
    for i in range(8):
        a = math.radians(i * 45)
        line(d, [(24 + 15 * math.cos(a), 24 + 15 * math.sin(a)), (24 + 20 * math.cos(a), 24 + 20 * math.sin(a))], 3)


def icon_clock(d):
    arc(d, (5, 5, 43, 43), 0, 360, 3.5)
    line(d, [(24, 12), (24, 24), (32, 30)], 3.5)


def icon_doc(d):
    d.polygon(pts([(10, 4), (30, 4), (38, 12), (38, 44), (10, 44)]), outline=W, width=int(s(3)))
    for y in (20, 27, 34):
        line(d, [(16, y), (32, y)], 2.5)


def icon_info(d):
    arc(d, (4, 4, 44, 44), 0, 360, 3.5)
    d.ellipse([s(21.5), s(11), s(26.5), s(16)], fill=W)
    line(d, [(24, 21), (24, 36)], 4)


def icon_helmet(d):
    d.chord([s(6), s(6), s(44), s(44)], 150, 360, fill=W)
    d.rectangle([s(26), s(18), s(46), s(28)], fill=(0, 0, 0, 0))
    d.polygon(pts([(28, 20), (46, 22), (44, 28), (28, 28)]), fill=W)
    d.polygon(pts([(8, 30), (24, 30), (30, 40), (12, 40)]), fill=W)


def icon_watch(d):
    d.rounded_rectangle([s(12), s(10), s(36), s(38)], radius=s(6), outline=W, width=s(3))
    d.rectangle([s(17), s(3), s(31), s(10)], fill=W)
    d.rectangle([s(17), s(38), s(31), s(45)], fill=W)
    for x, y in ((18, 17), (26, 17), (18, 25), (26, 25)):
        d.rounded_rectangle([s(x), s(y), s(x + 5), s(y + 5)], radius=s(1), fill=W)


def icon_compass(d):
    arc(d, (4, 22, 44, 40), 200, 340, 2.5)
    arc(d, (4, 22, 44, 40), 20, 160, 2.5)
    d.polygon(pts([(24, 18), (34, 36), (24, 32), (14, 36)]), fill=W)
    line(d, [(20, 13), (20, 4), (28, 13), (28, 4)], 2)


def icon_flag(d):
    line(d, [(12, 6), (12, 44)], 3)
    d.polygon(pts([(12, 6), (38, 12), (12, 24)]), fill=W)


def icon_mic(d):
    d.rounded_rectangle([s(17), s(4), s(31), s(30)], radius=s(7), fill=W)
    arc(d, (10, 14, 38, 38), 0, 180, 3)
    line(d, [(24, 38), (24, 44)], 3)


def icon_target(d):
    arc(d, (8, 8, 40, 40), 0, 360, 3)
    d.ellipse([s(18), s(18), s(30), s(30)], fill=W)
    for a, b in (((24, 2), (24, 8)), ((24, 40), (24, 46)), ((2, 24), (8, 24)), ((40, 24), (46, 24))):
        line(d, [a, b], 3)


def icon_layers(d):
    for k, y in enumerate((8, 18, 28)):
        d.polygon(pts([(24, y), (44, y + 8), (24, y + 16), (4, y + 8)]), fill=(255, 255, 255, 255 - k * 60))


def icon_plug(d):
    d.rounded_rectangle([s(14), s(16), s(34), s(32)], radius=s(4), fill=W)
    line(d, [(19, 6), (19, 16)], 3)
    line(d, [(29, 6), (29, 16)], 3)
    line(d, [(24, 32), (24, 44)], 4)


def icon_wrench(d):
    line(d, [(12, 38), (32, 18)], 5)
    arc(d, (26, 4, 44, 22), 120, 420, 4)


def icon_building(d):
    d.rectangle([s(10), s(8), s(26), s(44)], outline=W, width=s(3))
    d.rectangle([s(26), s(18), s(40), s(44)], outline=W, width=s(3))
    for y in (14, 22, 30):
        line(d, [(15, y), (21, y)], 2)


def icon_pin(d):
    d.ellipse([s(10), s(4), s(38), s(32)], fill=W)
    d.polygon(pts([(12, 24), (36, 24), (24, 44)]), fill=W)
    d.ellipse([s(18), s(12), s(30), s(24)], fill=(0, 0, 0, 0))


def icon_station(d):
    d.rounded_rectangle([s(8), s(6), s(30), s(44)], radius=s(3), outline=W, width=s(3))
    d.polygon(pts([(21, 12), (14, 26), (20, 26), (17, 36), (25, 22), (19, 22)]), fill=W)
    line(d, [(30, 16), (38, 20), (38, 36), (34, 40)], 2.5)


def icon_triangle(d):
    d.polygon(pts([(24, 4), (46, 42), (2, 42)]), outline=W, width=s(3))
    line(d, [(24, 16), (24, 30)], 3.5)
    d.ellipse([s(22), s(33), s(26), s(37)], fill=W)


def icon_back_curve(d):
    arc(d, (10, 12, 42, 40), 270, 90, 3.5)
    line(d, [(26, 12), (12, 12)], 3.5)
    head(d, (6, 12), 180, 12)


def icon_power(d):
    arc(d, (8, 10, 40, 42), 300, 240, 4)
    line(d, [(24, 4), (24, 22)], 4)


def icon_grid_plus(d):
    for x, y in ((8, 8), (26, 8), (8, 26)):
        d.rounded_rectangle([s(x), s(y), s(x + 14), s(y + 14)], radius=s(2), fill=W)
    line(d, [(33, 26), (33, 40)], 4)
    line(d, [(26, 33), (40, 33)], 4)


def icon_route_loop(d):
    arc(d, (6, 6, 42, 42), 60, 330, 4)
    head(d, (40, 18), 60, 12)
    d.ellipse([s(10), s(28), s(22), s(40)], fill=W)


def icon_fuel_can(d):
    d.rectangle([s(8), s(6), s(40), s(42)], outline=W, width=s(3))
    line(d, [(8, 14), (40, 14)], 3)
    line(d, [(8, 34), (40, 34)], 3)
    d.polygon(pts([(24, 16), (30, 26), (24, 31), (18, 26)]), fill=W)


def icon_sprout(d):
    line(d, [(24, 44), (24, 20)], 3)
    d.chord([s(2), s(10), s(26), s(34)], 180, 360, fill=W)
    d.chord([s(22), s(6), s(46), s(30)], 180, 360, fill=W)
    line(d, [(8, 44), (40, 44)], 3)


def icon_cloud(d):
    for box in ((6, 18, 24, 36), (16, 8, 36, 30), (28, 16, 44, 34)):
        arc(d, box, 0, 360, 2.5)
    d.rectangle([s(12), s(28), s(38), s(36)], fill=(0, 0, 0, 0))
    line(d, [(10, 36), (40, 36)], 2.5)


def icon_scooter_joystick(d):
    d.rounded_rectangle([s(6), s(6), s(42), s(42)], radius=s(8), outline=W, width=s(3))
    d.ellipse([s(18), s(18), s(30), s(30)], fill=W)


ICON_SET = {
    "helmet": icon_helmet,
    "watch": icon_watch,
    "compass": icon_compass,
    "flag": icon_flag,
    "mic": icon_mic,
    "target": icon_target,
    "layers": icon_layers,
    "plug": icon_plug,
    "wrench": icon_wrench,
    "building": icon_building,
    "pin": icon_pin,
    "station": icon_station,
    "triangle": icon_triangle,
    "back_curve": icon_back_curve,
    "power": icon_power,
    "grid_plus": icon_grid_plus,
    "route_loop": icon_route_loop,
    "fuel_can": icon_fuel_can,
    "sprout": icon_sprout,
    "cloud": icon_cloud,
    "joystick": icon_scooter_joystick,
    "indicator_left": lambda d: icon_indicator(d, True),
    "indicator_right": lambda d: icon_indicator(d, False),
    "high_beam": lambda d: icon_beam(d, True),
    "low_beam": lambda d: icon_beam(d, False),
    "abs": icon_abs,
    "warning": icon_warning,
    "battery_fault": icon_battery,
    "temp": icon_temp,
    "bluetooth": icon_bluetooth,
    "settings": icon_settings,
    "bell": lambda d: icon_bell(d, False),
    "mute": lambda d: icon_bell(d, True),
    "charging": icon_charging,
    "side_stand": icon_side_stand,
    "tyre": icon_tyre,
    "sos": icon_sos,
    "phone": icon_phone,
    "music": icon_music,
    "nav": icon_nav,
    "signal": icon_signal,
    "signal_full": icon_signal_full,
    "lock": icon_lock,
    "play": icon_play,
    "pause": icon_pause,
    "next": icon_next,
    "prev": lambda d: icon_next(d, True),
    "leaf": icon_leaf,
    "check": icon_check,
    "back": icon_back,
    "chevron": icon_chevron,
    "sun": icon_sun,
    "clock": icon_clock,
    "doc": icon_doc,
    "info": icon_info,
    "tt_left": lambda d: tt_chevron(d, True),
    "tt_right": lambda d: tt_chevron(d, False),
    "tt_high_beam": lambda d: tt_beam(d, True),
    "tt_low_beam": lambda d: tt_beam(d, False),
    "tt_warning": tt_warning,
    "tt_abs": tt_abs,
    "tt_battery": tt_battery,
}


# --------------------------------------------------------- turn arrows 128px
def turn_straight(d):
    line(d, [(64, 116), (64, 34)], 14)
    head(d, (64, 8), -90, 36)


def turn_curve(d, side, sharpness):
    sign = -1 if side == "left" else 1
    end_angle = {"slight": 45, "normal": 90, "sharp": 135}[sharpness]
    a = math.radians(end_angle)
    stem_top = (64, 70)
    r = 26
    cx = 64 + sign * r
    pts_list = [(64, 118), stem_top]
    for i in range(1, 13):
        t = a * i / 12
        pts_list.append((cx - sign * r * math.cos(t), stem_top[1] - r * math.sin(t)))
    lx, ly = pts_list[-1]
    dir_x, dir_y = sign * math.sin(a), -math.cos(a)
    tip = (lx + dir_x * 34, ly + dir_y * 34)
    tip = (min(max(tip[0], 10), 118), max(tip[1], 8))
    line(d, pts_list + [(lx + dir_x * 8, ly + dir_y * 8)], 14)
    head(d, tip, math.degrees(math.atan2(dir_y, dir_x)), 34)


def turn_uturn(d, side):
    sign = -1 if side == "left" else 1
    x0 = 80 if side == "left" else 48
    x1 = x0 + sign * 40
    line(d, [(x0, 118), (x0, 50)], 14)
    box = (min(x0, x1), 30, max(x0, x1), 70)
    arc(d, box, 180, 360, 14)
    line(d, [(x1, 50), (x1, 70)], 14)
    head(d, (x1, 104), 90, 34)


def turn_roundabout(d, exit_):
    arc(d, (36, 34, 92, 90), 0, 360, 10)
    line(d, [(64, 124), (64, 90)], 14)
    if exit_:
        line(d, [(92, 62), (104, 50)], 14)
        head(d, (122, 30), -45, 32)
    else:
        line(d, [(64, 34), (64, 26)], 14)
        head(d, (64, 4), -90, 32)


def turn_fork(d, side):
    sign = -1 if side == "left" else 1
    line(d, [(64, 118), (64, 70)], 14)
    line(d, [(64, 70), (64 - sign * 26, 34)], 8)
    line(d, [(64, 70), (64 + sign * 24, 38)], 14)
    head(d, (64 + sign * 44, 10), -90 + sign * 36, 34)


def turn_merge(d, side):
    sign = -1 if side == "left" else 1
    line(d, [(64 - sign * 36, 118), (64 - sign * 36, 84), (64, 56), (64, 36)], 14)
    line(d, [(64, 118), (64, 80)], 8)
    head(d, (64, 8), -90, 34)


def turn_destination(d):
    d.ellipse([s(34), s(10), s(94), s(70)], fill=W)
    d.polygon(pts([(38, 52), (90, 52), (64, 108)]), fill=W)
    d.ellipse([s(52), s(28), s(76), s(52)], fill=(0, 0, 0, 0))
    d.ellipse([s(40), s(108), s(88), s(122)], outline=W, width=int(s(4)))


TURN_SET = {
    "straight": turn_straight,
    "slight_left": lambda d: turn_curve(d, "left", "slight"),
    "left": lambda d: turn_curve(d, "left", "normal"),
    "sharp_left": lambda d: turn_curve(d, "left", "sharp"),
    "slight_right": lambda d: turn_curve(d, "right", "slight"),
    "right": lambda d: turn_curve(d, "right", "normal"),
    "sharp_right": lambda d: turn_curve(d, "right", "sharp"),
    "uturn_left": lambda d: turn_uturn(d, "left"),
    "uturn_right": lambda d: turn_uturn(d, "right"),
    "roundabout": lambda d: turn_roundabout(d, False),
    "roundabout_exit": lambda d: turn_roundabout(d, True),
    "fork_left": lambda d: turn_fork(d, "left"),
    "fork_right": lambda d: turn_fork(d, "right"),
    "merge_left": lambda d: turn_merge(d, "left"),
    "merge_right": lambda d: turn_merge(d, "right"),
    "destination": turn_destination,
}


# ------------------------------------------------------------------ frames
FRAME_W, FRAME_H = 800, 480


def bezel_points(inset=0):
    i = inset
    return [
        (60 + i, 8 + i), (740 - i, 8 + i), (792 - i, 70 + i), (792 - i, 330 - i),
        (730 - i, 410 - i), (560 - i, 410 - i), (530 - i, 472 - i), (270 + i, 472 - i),
        (240 + i, 410 - i), (70 + i, 410 - i), (8 + i, 330 - i), (8 + i, 70 + i),
    ]


def make_frame_glow():
    big = Image.new("RGBA", (FRAME_W * 2, FRAME_H * 2), (0, 0, 0, 0))
    d = ImageDraw.Draw(big)
    p = [(x * 2, y * 2) for x, y in bezel_points(6)]
    d.line(p + [p[0]], fill=W, width=10, joint="curve")
    glow = big.filter(ImageFilter.GaussianBlur(14))
    core = Image.new("RGBA", big.size, (0, 0, 0, 0))
    ImageDraw.Draw(core).line(p + [p[0]], fill=W, width=4, joint="curve")
    glow.alpha_composite(core)
    glow.resize((FRAME_W, FRAME_H), Image.LANCZOS).save(os.path.join(IMAGES, "frame_glow.png"))


def make_frame_mask():
    img = Image.new("RGBA", (FRAME_W, FRAME_H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    d.polygon(bezel_points(10), fill=W)
    img.save(os.path.join(IMAGES, "frame_fill.png"))


def make_bike():
    w, h = 260, 150
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    def S(p):
        return [(x * SS, y * SS) for x, y in p]

    d.ellipse([10 * SS, 70 * SS, 80 * SS, 140 * SS], outline=W, width=8 * SS)
    d.ellipse([180 * SS, 70 * SS, 250 * SS, 140 * SS], outline=W, width=8 * SS)
    d.ellipse([36 * SS, 96 * SS, 54 * SS, 114 * SS], fill=W)
    d.ellipse([206 * SS, 96 * SS, 224 * SS, 114 * SS], fill=W)
    d.polygon(S([(70, 60), (150, 40), (200, 46), (222, 62), (190, 70), (150, 96), (96, 100), (78, 84)]), fill=W)
    d.polygon(S([(40, 56), (110, 48), (104, 62), (46, 66)]), fill=W)
    d.line(S([(184, 60), (215, 104)]), fill=W, width=7 * SS)
    d.line(S([(96, 92), (45, 105)]), fill=W, width=7 * SS)
    d.line(S([(190, 44), (178, 22), (196, 18)]), fill=W, width=5 * SS)
    d.polygon(S([(104, 64), (150, 60), (146, 90), (108, 92)]), fill=(0, 0, 0, 0))
    d.rectangle([110 * SS, 66 * SS, 144 * SS, 86 * SS], outline=W, width=3 * SS)
    img.resize((w, h), Image.LANCZOS).save(os.path.join(IMAGES, "bike.png"))


def make_segment():
    w, h = 64, 20
    img = Image.new("RGBA", (w * SS, h * SS), (0, 0, 0, 0))
    ImageDraw.Draw(img).polygon([(6 * SS, 0), (w * SS, 0), ((w - 6) * SS, h * SS), (0, h * SS)], fill=W)
    img.resize((w, h), Image.LANCZOS).save(os.path.join(IMAGES, "segment.png"))


def make_glow_blob(w, h):
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    px = img.load()
    cx, cy = (w - 1) / 2, (h - 1) / 2
    for y in range(h):
        for x in range(w):
            dist = math.hypot((x - cx) / cx, (y - cy) / cy)
            a = max(0.0, 1.0 - dist) ** 2.2
            px[x, y] = (255, 255, 255, int(a * 255))
    img.save(os.path.join(IMAGES, f"glow_blob_{w}x{h}.png"))


def make_road_grid():
    w, h = 600, 260
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    horizon = 20
    vx = w / 2
    for i in range(-14, 15):
        x = vx + i * 70
        d.line([(vx + i * 6, horizon), (x, h)], fill=(255, 255, 255, 70), width=1)
    y = horizon + 4
    step = 6
    while y < h:
        alpha = int(40 + 120 * (y - horizon) / (h - horizon))
        d.line([(0, y), (w, y)], fill=(255, 255, 255, alpha), width=1)
        step *= 1.25
        y += step
    img.save(os.path.join(IMAGES, "road_grid.png"))


def used_images():
    """Sizes are baked into the paths because Qt Quick Ultralite does not scale images."""
    icons, turns, blobs = set(), set(), set()
    pattern = re.compile(r"qrc:/assets/(icons|turns)/(\d+)/(\w+)\.png|qrc:/assets/images/glow_blob_(\d+)x(\d+)\.png")
    for folder, _, files in os.walk(os.path.join(ROOT, "qml")):
        for name in files:
            if not name.endswith(".qml"):
                continue
            with open(os.path.join(folder, name)) as fh:
                for m in pattern.finditer(fh.read()):
                    if m.group(1) == "icons":
                        icons.add((int(m.group(2)), m.group(3)))
                    elif m.group(1) == "turns":
                        turns.add((int(m.group(2)), m.group(3)))
                    else:
                        blobs.add((int(m.group(4)), int(m.group(5))))
    return icons, turns, blobs


def clean(folder):
    if os.path.isdir(folder):
        shutil.rmtree(folder)
    os.makedirs(folder)


def main():
    icons, turns, blobs = used_images()
    clean(ICONS)
    clean(TURNS)
    clean(IMAGES)
    for size, name in sorted(icons):
        if name not in ICON_SET:
            raise SystemExit(f"unknown icon '{name}'")
        img, d = canvas(48)
        ICON_SET[name](d)
        save(img, size, os.path.join(ICONS, str(size)), name)
    for size, name in sorted(turns):
        if name not in TURN_SET:
            raise SystemExit(f"unknown turn arrow '{name}'")
        img, d = canvas(128)
        TURN_SET[name](d)
        save(img, size, os.path.join(TURNS, str(size)), name)
    for w, h in sorted(blobs):
        make_glow_blob(w, h)
    print("icons:", len(icons), "turns:", len(turns), "glow blobs:", len(blobs))


if __name__ == "__main__":
    main()
