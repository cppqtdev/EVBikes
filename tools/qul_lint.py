#!/usr/bin/env python3
"""Checks QML files only use imports and types available in Qt Quick Ultralite.

Usage: python3 tools/qul_lint.py [qml_dir]
Lists come from the Qt for MCUs 2.12 "All QML types" reference. Update them
when you move to a newer Qt for MCUs release.
"""
import os
import re
import sys

ALLOWED_IMPORTS = {
    "QtQuick", "QtQuick.Controls", "QtQuick.Layouts", "QtQuick.Shapes", "QtQuick.Timeline",
    "QtLocation", "QtPositioning", "QtQuickUltralite.Extras", "QtQuickUltralite.Layers",
    "QtQuickUltralite.SafeRenderer", "QtQuickUltralite.Studio.Components",
    "QtQuickUltralite.Profiling", "QtQuick.VirtualKeyboard",
}

QUL_TYPES = set("""
AnchorChanges AnimatedSprite Animation Behavior BorderImage ColorAnimation Column Component
Connections Flickable Gradient GradientStop Image Item KeyEvent Keys ListElement ListModel
ListView Loader Matrix4x4 MouseArea MouseEvent NumberAnimation ParallelAnimation Path PathArc
PathCubic PathElement PathLine PathMove PathQuad PathSvg PathView PauseAnimation
PropertyAnimation PropertyChanges QtObject Rectangle Repeater Rotation RotationAnimation Row
Scale ScriptAction SequentialAnimation State StateGroup Text TextInput Timer Transform
Transition Translate
AbstractButton Button CheckBox Control Dial ProgressBar RadioButton Slider SwipeView Switch
ColumnLayout GridLayout Layout RowLayout
LinearGradient Shape ShapeGradient ShapePath
Keyframe KeyframeGroup Timeline TimelineAnimation
Map MapQuickItem CoordinateAnimation Position PositionSource
AnimatedSpriteDirectory ColorizedImage PaintedItem StaticText SafeText
Application ApplicationScreens ImageLayer ItemLayer Screen SpriteLayer
SafeImage SafePicture ArcItem QulPerfOverlay
""".split())

# Types that exist in desktop Qt Quick but not in Qt Quick Ultralite.
KNOWN_MISSING = {
    "Window", "ApplicationWindow", "Grid", "Flow", "Canvas", "ShaderEffect", "DropShadow",
    "Glow", "OpacityMask", "FastBlur", "MultiEffect", "TextEdit", "TextArea", "TextField",
    "ComboBox", "Popup", "Dialog", "Drawer", "StackView", "Menu", "ToolTip", "Label",
    "BusyIndicator", "ScrollView", "TableView", "GridView", "WebView", "Video", "MediaPlayer",
    "FontLoader", "Instantiator", "ObjectModel", "DelegateModel", "WorkerScript", "XmlListModel",
    "SpringAnimation", "SmoothedAnimation", "PinchArea", "Flipable", "ShaderEffectSource",
}

# Types that only exist once their module is imported. Using one without the
# import fails at load with "X is not a type", which no other rule here catches
# because the type itself is perfectly valid.
NEEDS_IMPORT = {
    "Shape": "QtQuick.Shapes",
    "ShapePath": "QtQuick.Shapes",
    "ShapeGradient": "QtQuick.Shapes",
    "LinearGradient": "QtQuick.Shapes",
    "RowLayout": "QtQuick.Layouts",
    "ColumnLayout": "QtQuick.Layouts",
    "GridLayout": "QtQuick.Layouts",
    "Timeline": "QtQuick.Timeline",
    "TimelineAnimation": "QtQuick.Timeline",
    "Keyframe": "QtQuick.Timeline",
    "KeyframeGroup": "QtQuick.Timeline",
    "ColorizedImage": "QtQuickUltralite.Extras",
    "PaintedItem": "QtQuickUltralite.Extras",
    "StaticText": "QtQuickUltralite.Extras",
    "ArcItem": "QtQuickUltralite.Extras",
    "AnimatedSpriteDirectory": "QtQuickUltralite.Extras",
    "Button": "QtQuick.Controls",
    "CheckBox": "QtQuick.Controls",
    "Slider": "QtQuick.Controls",
    "Switch": "QtQuick.Controls",
    "Dial": "QtQuick.Controls",
    "ProgressBar": "QtQuick.Controls",
    "RadioButton": "QtQuick.Controls",
    "SwipeView": "QtQuick.Controls",
}

# qmltocpp wants a type on every function parameter, and a return type on any
# function that returns a value. An untyped parameter is a build error.
FUNCTION_RE = re.compile(r"^\s*function\s+(\w+)\s*\(([^)]*)\)")

TYPE_RE = re.compile(r"^\s*([A-Z][A-Za-z0-9_]*)\s*\{")
ANIM_ON_RE = re.compile(r"^\s*([A-Z][A-Za-z0-9_]*)\s+on\s+\w+\s*\{")
IMPORT_RE = re.compile(r"^\s*import\s+([A-Za-z0-9_.]+)")
BANNED_PATTERNS = [
    (re.compile(r"\bborder\s*\.|\bborder\s*:"), "Rectangle.border is not available in Qt Quick Ultralite"),
    (re.compile(r"\bLoader\b.*\.item\b"), "Loader.item cannot be accessed in Qt Quick Ultralite"),
    (re.compile(r"\bQt\.createComponent|\bcreateObject\s*\("), "dynamic object creation is not supported"),
    (re.compile(r"\bJSON\.|\bXMLHttpRequest\b|\bPromise\b"), "JavaScript API not available"),
    (re.compile(r"\banchors\.baseline\b"), "avoid baseline anchors; align with bottom + margin"),
    (re.compile(r"\blayer\.enabled\b"), "layer.enabled is not available; use pre-rendered images"),
    (re.compile(r"\.(charAt|substring|substr|toUpperCase|toLowerCase|indexOf|split|trim)\s*\("),
     "String methods are not in the Qt for MCUs JavaScript subset"),
    (re.compile(r"\"\s*\+[^\n]*\)\.length\b|\bstring[A-Za-z0-9_]*\.length\b"),
     "String.length is not in the Qt for MCUs JavaScript subset"),
    (re.compile(r"\bfont\.weight\b"),
     "font.weight compiles only for the Monotype Spark font engine; "
     "the static engine picks a face by family, bold and italic"),
]


#  One ternary, two types. Qt for MCUs will not merge an enum constant with an
#  int property into one value: "could not load value of ambiguous type".
TERNARY = re.compile(r"\?([^?:]+):([^?:]+?)(?:$|\))")
ENUM_SHAPE = re.compile(r"^\w+\.[A-Z]\w*$")


def mixed_enum_ternary(line):
    m = TERNARY.search(line)
    if not m:
        return False
    left, right = m.group(1).strip(), m.group(2).strip()
    if not left or not right:
        return False
    return bool(ENUM_SHAPE.match(left)) != bool(ENUM_SHAPE.match(right))


#  The static font engine takes a font configuration only if qmltocpp can
#  resolve every subproperty at compile time. A literal counts, and so does a
#  binding to a readonly property; anything else has to become a whole font.
FONT_SUB = re.compile(r"^\s*font\.(\w+)\s*:\s*(.+?)\s*$")
FONT_CONST = {
    "family": re.compile(r'^"[^"]*"$|^Theme\.fontFamily$'),
    "pixelSize": re.compile(r"^\d+$|^Theme\.font[A-Z]\w*$|^\w+\.labelSize$"),
    "bold": re.compile(r"^(true|false)$"),
    "italic": re.compile(r"^(true|false)$"),
    "weight": re.compile(r"^$"),
}


def runtime_font_binding(line):
    m = FONT_SUB.match(line)
    if not m:
        return None
    prop, value = m.group(1), m.group(2)
    rx = FONT_CONST.get(prop)
    if rx is None or rx.match(value):
        return None
    return (f"font.{prop} cannot be bound to '{value}' with the static font "
            f"engine; bind the whole font to a readonly Qt.font(...) instead")


#  A font can be built but not read back, so NumberReadout is told its digit
#  size twice. The two have to agree.
DIGIT_SIZE = re.compile(r"^\s*digitSize:\s*(\d+)\s*$")
DIGIT_FONT = re.compile(r"^\s*digitFont:\s*Qt\.font\(\{[^}]*pixelSize:\s*(\d+)")
FONT_READ = re.compile(r"\b\w+[Ff]ont\.(pixelSize|family|bold|italic|weight)\b")


def font_problems(path, lines):
    """Size/font mismatches, and reads of a font's subproperties."""
    out = []
    pending = None
    for n, line in enumerate(lines, 1):
        m = DIGIT_SIZE.match(line)
        if m:
            pending = (n, int(m.group(1)))
            continue
        m = DIGIT_FONT.match(line)
        if m:
            if pending is None:
                out.append(f"{path}:{n}: digitFont without a digitSize beside it")
            elif pending[1] != int(m.group(1)):
                out.append(f"{path}:{n}: digitSize {pending[1]} does not match "
                           f"the font's pixelSize {m.group(1)}")
            pending = None
            continue
        bare = re.sub(r'"[^"]*"', '""', line)
        if re.match(r"\s*font\.", bare) or "Qt.font(" in bare:
            continue
        r = FONT_READ.search(bare)
        if r:
            out.append(f"{path}:{n}: a font's '{r.group(1)}' cannot be read back "
                       f"in Qt for MCUs; keep the value in its own property")
    return out


PROP_DECL = re.compile(r"\s*(?:readonly\s+)?property\s+\w+\s+(\w+)\s*:\s*(.+?)\s*$")
LITERAL = re.compile(r'^(-?\d+(\.\d+)?|"[^"]*"|true|false)$')
BEHAVIOR_ON = re.compile(r"\s*Behavior\s+on\s+(\w+)")


def behavior_problems(path, lines):
    """A Behavior on a declared property that also carries a binding.

    Qt for MCUs re-runs a dirty property's binding every time the value is
    read. The Behavior catches that write and restarts, which dirties the
    property again, so any binding that reads it keeps the frame alive and the
    engine never finishes it. Assign the property from a signal handler
    instead; a Behavior is for assignments.
    """
    bound = {}
    for n, line in enumerate(lines, 1):
        m = PROP_DECL.match(line.split("//")[0])
        if m and not LITERAL.match(m.group(2)):
            bound[m.group(1)] = n
    out = []
    for n, line in enumerate(lines, 1):
        m = BEHAVIOR_ON.match(line)
        if m and m.group(1) in bound:
            out.append(f"{path}:{n}: Behavior on '{m.group(1)}', which is bound "
                       f"at line {bound[m.group(1)]}; assign it from a signal "
                       f"handler instead or the frame never finishes")
    return out


def collect_local_types(root):
    names = set()
    for dirpath, _, files in os.walk(root):
        for f in files:
            if f.endswith(".qml"):
                names.add(f[:-4])
    return names


def lint(root):
    local = collect_local_types(root)
    problems = 0
    for dirpath, _, files in os.walk(root):
        for f in sorted(files):
            if not f.endswith(".qml"):
                continue
            path = os.path.join(dirpath, f)
            module_imports = {"ClusterBackend", "ClusterCore", "ClusterComponents", "ClusterScreens"}
            imported = set()
            missing_import = {}
            with open(path, encoding="utf-8") as fh:
                for n, line in enumerate(fh, 1):
                    stripped = line.split("//")[0]
                    m = IMPORT_RE.match(stripped)
                    if m:
                        mod = m.group(1)
                        imported.add(mod)
                        if mod not in ALLOWED_IMPORTS and mod not in module_imports:
                            print(f"{path}:{n}: import '{mod}' is not a Qt Quick Ultralite module")
                            problems += 1
                        continue
                    opener = TYPE_RE.match(stripped)
                    if opener and opener.group(1) in NEEDS_IMPORT and opener.group(1) not in local:
                        missing_import.setdefault(opener.group(1), n)
                    for rx in (TYPE_RE, ANIM_ON_RE):
                        t = rx.match(stripped)
                        if not t:
                            continue
                        name = t.group(1)
                        if name in local:
                            continue
                        if name in KNOWN_MISSING:
                            print(f"{path}:{n}: '{name}' is not available in Qt Quick Ultralite")
                            problems += 1
                        elif name not in QUL_TYPES and name not in local:
                            print(f"{path}:{n}: unknown type '{name}'")
                            problems += 1
                    on_match = ANIM_ON_RE.match(stripped)
                    if on_match and on_match.group(1) != "Behavior":
                        print(f"{path}:{n}: '<Animation> on <property>' syntax: prefer an explicit animation with target/property")
                        problems += 1
                    fn = FUNCTION_RE.match(stripped)
                    if fn and fn.group(2).strip():
                        for arg in fn.group(2).split(","):
                            if ":" not in arg:
                                print(f"{path}:{n}: parameter '{arg.strip()}' of "
                                      f"{fn.group(1)}() needs a type")
                                problems += 1
                    for rx, msg in BANNED_PATTERNS:
                        if rx.search(stripped):
                            print(f"{path}:{n}: {msg}")
                            problems += 1
                    bad_font = runtime_font_binding(line)
                    if bad_font:
                        print(f"{path}:{n}: {bad_font}")
                        problems += 1
                    if mixed_enum_ternary(stripped):
                        print(f"{path}:{n}: one side of this ternary is an enum "
                              f"constant and the other is not; Qt for MCUs "
                              f"cannot merge the two types")
                        problems += 1
            text = open(path, encoding="utf-8").read().split("\n")
            for msg in font_problems(path, text) + behavior_problems(path, text):
                print(msg)
                problems += 1
            for name, n in sorted(missing_import.items(), key=lambda kv: kv[1]):
                module = NEEDS_IMPORT[name]
                if module not in imported:
                    print(f"{path}:{n}: '{name}' needs 'import {module}'")
                    problems += 1
    return problems


if __name__ == "__main__":
    target = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(__file__), "..", "qml")
    count = lint(target)
    print("qul_lint: %d problem(s)" % count)
    #  Imports and types are only half of it; qul_types checks the members.
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import qul_types
    count += qul_types.scan(target)
    sys.exit(1 if count else 0)
