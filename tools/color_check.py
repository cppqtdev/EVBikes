#!/usr/bin/env python3
"""Fails when a dark near-grey colour literal carries a colour cast.

The reference frames draw every dark surface as a neutral grey: red, green and
blue are within a couple of steps of each other. Hand-written QML kept drifting
towards teal, which made the whole cluster look green next to the reference.
A literal darker than 0x5A whose channels spread by 4..10 steps is that drift.
Deliberate colours (the teal segments, the green boot chrome) spread much more.
"""
import os
import re
import sys

PATTERN = re.compile(r'"#([0-9A-Fa-f]{6})"')
MAX_LEVEL = 0x5A
MIN_SPREAD = 4
MAX_SPREAD = 10


def problems(root):
    found = []
    for base, _, files in os.walk(root):
        for name in sorted(files):
            if not name.endswith(".qml"):
                continue
            path = os.path.join(base, name)
            for number, line in enumerate(open(path), 1):
                for match in PATTERN.finditer(line):
                    text = match.group(1)
                    channels = [int(text[i:i + 2], 16) for i in (0, 2, 4)]
                    spread = max(channels) - min(channels)
                    if max(channels) < MAX_LEVEL and MIN_SPREAD <= spread <= MAX_SPREAD:
                        grey = round(0.299 * channels[0] + 0.587 * channels[1]
                                     + 0.114 * channels[2])
                        found.append((path, number, "#" + text.upper(),
                                      "#%02X%02X%02X" % (grey, grey, grey)))
    return found


if __name__ == "__main__":
    hits = problems(sys.argv[1] if len(sys.argv) > 1 else "qml")
    for path, number, was, want in hits:
        print(f"{path}:{number}: {was} has a colour cast, use {want}")
    print(f"color_check: {len(hits)} problem(s)")
    sys.exit(1 if hits else 0)
