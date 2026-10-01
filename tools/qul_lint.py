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
]


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
                    for rx, msg in BANNED_PATTERNS:
                        if rx.search(stripped):
                            print(f"{path}:{n}: {msg}")
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
    sys.exit(1 if count else 0)
