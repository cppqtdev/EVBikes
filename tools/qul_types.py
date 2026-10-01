#!/usr/bin/env python3
"""Check QML against the Qt for MCUs type system.

Qt for MCUs knows a smaller version of each Qt Quick type than the desktop
does, so a member that reads fine in Qt Creator stops qmltocpp instead:
Text has no contentWidth, parent is a plain Item, Rectangle has no border.
This checks both directions -- the properties a file assigns, and the members
it reads through an id -- against the Qt for MCUs 2.12 documented members.

    python3 tools/qul_types.py qml
"""
import os
import re
import sys
import collections

#  type: (what it extends, the members it adds)
BUILTIN = {
    "QtObject":   (None, {"id", "objectName"}),
    "Item":       ("QtObject", {
        "x", "y", "z", "width", "height", "implicitWidth", "implicitHeight",
        "opacity", "visible", "clip", "enabled", "parent", "anchors", "children",
        "data", "state", "states", "transitions", "activeFocus", "focus",
        "baselineOffset", "childAt"}),
    "Rectangle":  ("Item", {"color", "gradient", "radius"}),
    "Text":       ("Item", {
        "color", "font", "text", "elide", "wrapMode", "horizontalAlignment",
        "verticalAlignment", "lineHeight", "lineHeightMode", "maximumLineCount",
        "textFormat", "truncated", "padding", "leftPadding", "rightPadding",
        "topPadding", "bottomPadding", "rotation", "scale", "transform",
        "transformOrigin"}),
    "StaticText": ("Text", set()),
    "Image":      ("Item", {
        "source", "rotation", "scale", "transform", "transformOrigin", "status",
        "sourceSize", "horizontalAlignment", "verticalAlignment"}),
    "ColorizedImage": ("Image", {"color"}),
    "Column":     ("Item", {"spacing", "padding"}),
    "Row":        ("Item", {"spacing", "padding"}),
    "Repeater":   ("Item", {"model", "delegate", "count"}),
    "PathView":   ("Item", {
        "model", "delegate", "path", "count", "currentIndex", "pathItemCount",
        "preferredHighlightBegin", "preferredHighlightEnd", "interactive",
        "incrementCurrentIndex", "decrementCurrentIndex"}),
    "ListModel":  ("QtObject", {"count"}),
    "Timer":      ("QtObject", {
        "interval", "repeat", "running", "triggeredOnStart",
        "start", "stop", "restart"}),
    "Shape":      ("Item", set()),
    "ShapePath":  ("QtObject", {
        "strokeColor", "strokeWidth", "fillColor", "capStyle", "joinStyle",
        "startX", "startY", "fillRule", "strokeStyle"}),
    "Path":       ("QtObject", {"startX", "startY"}),
    "PathArc":    ("QtObject", {"x", "y", "radiusX", "radiusY", "useLargeArc",
                                "direction"}),
    "PathLine":   ("QtObject", {"x", "y"}),
    "PathCubic":  ("QtObject", {"x", "y", "control1X", "control1Y",
                                "control2X", "control2Y"}),
    "PathQuad":   ("QtObject", {"x", "y", "controlX", "controlY"}),
    "PathMove":   ("QtObject", {"x", "y"}),
    "Gradient":   ("QtObject", {"stops", "orientation"}),
    "GradientStop": ("QtObject", {"position", "color"}),
    "Connections": ("QtObject", {"target", "enabled"}),
    "NumberAnimation": ("QtObject", {
        "target", "property", "properties", "from", "to", "duration", "easing",
        "running", "paused", "loops", "alwaysRunToEnd"}),
    "ColorAnimation": ("NumberAnimation", set()),
    "PropertyAnimation": ("NumberAnimation", set()),
    "RotationAnimation": ("NumberAnimation", {"direction"}),
    "SequentialAnimation": ("QtObject", {"running", "paused", "loops",
                                         "alwaysRunToEnd"}),
    "ParallelAnimation": ("SequentialAnimation", set()),
    "PauseAnimation": ("QtObject", {"duration", "running", "loops"}),
    "Behavior":    ("QtObject", {"enabled", "animation"}),
    "Rotation":    ("QtObject", {"origin", "angle", "axis"}),
    "Scale":       ("QtObject", {"origin", "xScale", "yScale"}),
    "Translate":   ("QtObject", {"x", "y"}),
}

#  Value types, checked as "<group>.<leaf>".
GROUPED = {
    "anchors": {
        "left", "right", "top", "bottom", "horizontalCenter", "verticalCenter",
        "baseline", "fill", "centerIn", "margins", "leftMargin", "rightMargin",
        "topMargin", "bottomMargin", "horizontalCenterOffset",
        "verticalCenterOffset", "baselineOffset"},
    "font": {"family", "pixelSize", "bold", "italic", "weight", "letterSpacing",
             "capitalization", "underline", "strikeout", "wordSpacing"},
    "easing": {"type", "amplitude", "period", "overshoot", "bezierCurve"},
    "origin": {"x", "y"},
    "axis": {"x", "y", "z"},
}

#  Anchoring to another item names one of its anchor lines, not a property.
ANCHOR_LINES = {"left", "right", "top", "bottom", "horizontalCenter",
                "verticalCenter", "baseline"}

DECL = re.compile(r'^\s*(?:readonly\s+)?(?:default\s+)?property\s+(?:alias\s+)?([A-Za-z_]\w*)\s*:')
PROP = re.compile(r'^\s*(?:readonly\s+)?(?:default\s+)?property\s+\S+\s+([A-Za-z_]\w*)')
FUNC = re.compile(r'^\s*function\s+([A-Za-z_]\w*)')
SIG = re.compile(r'^\s*signal\s+([A-Za-z_]\w*)')
MEMBER = re.compile(r'^\s*(?:readonly\s+|default\s+)?(?:property|function|signal)\b')
ELEM = re.compile(r'^(\s*)([A-Z][A-Za-z0-9_]*)\s*\{')
INLINE = re.compile(r'^(\s*)[a-z]\w*\s*:\s*([A-Z][A-Za-z0-9_]*)\s*\{')
IDLINE = re.compile(r'^\s*id\s*:\s*([A-Za-z_]\w*)')
ASSIGN = re.compile(r'^\s*([a-z]\w*)(?:\.(\w+))?\s*:')
REF = re.compile(r'\b([a-z]\w*)\.([a-z]\w*)')


def builtin_members(name):
    out = set()
    while name:
        parent, props = BUILTIN[name]
        out |= props
        name = parent
    return out


def is_handler(name):
    return name.startswith("on") and len(name) > 2 and name[2].isupper()


def scan(root):
    files = []
    for dirpath, _, names in os.walk(root):
        for n in sorted(names):
            if n.endswith(".qml"):
                files.append(os.path.join(dirpath, n))

    #  Pass 1: what each component in the tree extends, and what it adds.
    comp_root, comp_own = {}, collections.defaultdict(set)
    for path in files:
        name = os.path.basename(path)[:-4]
        depth = None
        for line in open(path, encoding="utf-8"):
            m = ELEM.match(line)
            if m and depth is None:
                comp_root[name] = m.group(2)
                depth = len(m.group(1))
                continue
            if depth is None:
                continue
            if line.strip() and len(line) - len(line.lstrip()) == depth + 4:
                for rx in (PROP, DECL, FUNC, SIG):
                    mm = rx.match(line)
                    if mm:
                        comp_own[name].add(mm.group(1))
                        break

    def members(name, seen=()):
        """Every member a type exposes, or None when the type is not ours."""
        if name in BUILTIN:
            return builtin_members(name)
        if name in comp_root and name not in seen:
            base = members(comp_root[name], seen + (name,))
            if base is None:
                return None
            return comp_own[name] | base
        return None          # a singleton, a backend type, or an enum holder

    problems = []
    for path in files:
        lines = open(path, encoding="utf-8").read().split("\n")
        this = os.path.basename(path)[:-4]

        #  Pass 2a: id -> type, and the properties each id's own object adds.
        idtype, extra = {}, collections.defaultdict(set)
        stack, pending, first = [], None, True
        for line in lines:
            m = ELEM.match(line) or INLINE.match(line)
            if m:
                ind = len(m.group(1))
                while stack and stack[-1][2] >= ind:
                    stack.pop()
                #  The root element is this component, not the bare type it
                #  extends: its own properties are what the id sees.
                pending = this if first else m.group(2)
                first = False
                stack.append((pending, None, ind))
                continue
            i = IDLINE.match(line)
            if i and pending:
                idtype[i.group(1)] = pending
                if stack:
                    stack[-1] = (stack[-1][0], i.group(1), stack[-1][2])
                continue
            owner = stack[-1][1] if stack else None
            if owner:
                for rx in (PROP, DECL, FUNC, SIG):
                    mm = rx.match(line)
                    if mm:
                        extra[owner].add(mm.group(1))
                        break

        #  Pass 2b: every property assigned, and every member read by id.
        stack = []
        for n, line in enumerate(lines, 1):
            s = line.strip()
            if not s or s.startswith("//"):
                continue
            m = ELEM.match(line) or INLINE.match(line)
            if m:
                ind = len(m.group(1))
                while stack and stack[-1][1] >= ind:
                    stack.pop()
                stack.append((m.group(2), ind))
            elif s.startswith("}") and stack:
                stack.pop()
            elif stack and not MEMBER.match(line):
                a = ASSIGN.match(line)
                t = stack[-1][0]
                allowed = members(t)
                if a and allowed is not None and is_handler(a.group(1)) \
                        and t not in BUILTIN:
                    #  onFooChanged needs a foo; onBar needs a bar signal.
                    base = a.group(1)[2].lower() + a.group(1)[3:]
                    want = base[:-7] if base.endswith("Changed") else base
                    if want and want not in allowed:
                        problems.append(
                            f"{path}:{n}: {t} has nothing called '{want}' "
                            f"for {a.group(1)} to handle")
                if a and allowed is not None and not is_handler(a.group(1)):
                    group, leaf = a.group(1), a.group(2)
                    if group not in allowed:
                        problems.append(
                            f"{path}:{n}: {t} has no '{group}' in Qt for MCUs")
                    elif leaf and group in GROUPED and leaf not in GROUPED[group]:
                        problems.append(
                            f"{path}:{n}: {t}.{group} has no '{leaf}' in Qt for MCUs")

            bare = re.sub(r'"[^"]*"', '""', line)
            for ident, member in REF.findall(bare):
                if ident == "parent":
                    #  Qt for MCUs types parent as a plain Item, so a custom
                    #  property of the parent is only reachable through its id.
                    if member not in builtin_members("Item") | ANCHOR_LINES:
                        problems.append(
                            f"{path}:{n}: parent is a plain Item here; read "
                            f"'{member}' through the parent's id instead")
                    continue
                t = idtype.get(ident)
                if t is None:
                    continue
                allowed = members(t)
                if allowed is None:
                    continue
                allowed = allowed | extra.get(ident, set()) | ANCHOR_LINES
                if member not in allowed:
                    problems.append(
                        f"{path}:{n}: {ident} is a {t}; it has no '{member}'")

    for p in problems:
        print(p)
    print(f"\n{len(problems)} problem(s) in {len(files)} file(s)")
    return len(problems)


if __name__ == "__main__":
    sys.exit(1 if scan(sys.argv[1] if len(sys.argv) > 1 else "qml") else 0)
