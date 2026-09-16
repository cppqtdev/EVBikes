# 06 · Qt Quick Ultralite rules (what you can and cannot use)

Qt Quick Ultralite is a **subset** of Qt Quick compiled to C++. If a type is not in the list below, the build fails.
Run `python3 tools/qul_lint.py qml` before every commit.

## Available QML types (Qt for MCUs 2.12)

| Module (import) | Types |
|---|---|
| `QtQuick` | AnchorChanges, AnimatedSprite, Animation, Behavior, BorderImage, ColorAnimation, Column, Component, Connections, Flickable, Gradient, GradientStop, Image, Item, KeyEvent, Keys, ListElement, ListModel, ListView, Loader, Matrix4x4, MouseArea, MouseEvent, NumberAnimation, ParallelAnimation, Path, PathArc, PathCubic, PathElement, PathLine, PathMove, PathQuad, PathSvg, PathView, PauseAnimation, PropertyAnimation, PropertyChanges, QtObject, Rectangle, Repeater, Rotation, RotationAnimation, Row, Scale, ScriptAction, SequentialAnimation, State, StateGroup, Text, TextInput, Timer, Transform, Transition, Translate |
| `QtQuick.Controls` | AbstractButton, Button, CheckBox, Control, Dial, ProgressBar, RadioButton, Slider, SwipeView, Switch |
| `QtQuick.Layouts` | ColumnLayout, GridLayout, Layout, RowLayout |
| `QtQuick.Shapes` | Shape, ShapePath, ShapeGradient, LinearGradient |
| `QtQuick.Timeline` | Timeline, TimelineAnimation, Keyframe, KeyframeGroup |
| `QtLocation` / `QtPositioning` | Map, MapQuickItem / PositionSource, Position, CoordinateAnimation |
| `QtQuickUltralite.Extras` | ColorizedImage, StaticText, AnimatedSpriteDirectory, PaintedItem, Qul, QulPerf |
| `QtQuickUltralite.Layers` | Application, ApplicationScreens, Screen, ItemLayer, ImageLayer, SpriteLayer |
| `QtQuickUltralite.SafeRenderer` | SafeImage, SafePicture, SafeText |
| `QtQuickUltralite.Studio.Components` | ArcItem |
| `QtQuickUltralite.Profiling` | QulPerfOverlay |

Modules other than QtQuick / Extras must be enabled in the `.qmlproject`: `ModuleFiles { MCU.qulModules: ["Shapes", "Controls", ...] }`.

## Not available (use the alternative)

| Desktop Qt Quick | Use instead |
|---|---|
| `Window`, `ApplicationWindow` | Root `Rectangle` / `Item` |
| `Grid`, `Flow`, `GridView` | `Row` + `Column`, or fixed `x/y` (see `Grid2x2.qml`) |
| `Canvas`, shaders, `MultiEffect`, `DropShadow`, `Glow` | Pre-rendered PNG + `ColorizedImage` |
| `Rectangle.border` | Inner `Rectangle` or a thin `Rectangle` line |
| `Label`, `TextField`, `ComboBox`, `Popup`, `StackView` | `Text`, `TextInput`, own components, visibility / `Loader` |
| Different corner radii | One `radius` for all corners |
| `Loader.item` access | Bind to shared state (singletons) instead |
| `Qt.createComponent`, `createObject` | Static items, `Loader`, `Repeater` |
| `JSON`, `XMLHttpRequest`, heavy JavaScript | Do it in C++ |
| `anchors.baseline` (avoid) | `anchors.bottom` + margin |
| `States` with `when:` conditions (known issue) | Plain property bindings |

## Patterns used in this project

- **C++ → QML**: struct derived from `Qul::Singleton<T>` with `Qul::Property<T>` fields, listed in `InterfaceFiles` of a module qmlproject (`qml/backend/backend.qmlproject`). QML uses `import ClusterBackend` then `VehicleData.speedKmh`.
- **Types**: `bool`, integers → `int`, `float/double` → `real`, `std::string` → `string`, public enums → QML enums (`VehicleData.Sport`).
- **Signals**: `Qul::Signal<void(int button, int action)>` → `Connections { target: ClusterInput; function onButtonEvent(button: int, action: int) { ... } }`. Do not mix this with the old `onFoo:` form in the same `Connections` (Ultralite then ignores the function handlers).
- **Threads / ISR**: only `Qul::EventQueue<T>::postEvent / postEventFromInterrupt`; handle in `onEvent` (UI thread).
- **QML singletons**: `pragma Singleton` inside a QML module (`qml/core`).
- **Modules**: each folder has its own `.qmlproject` with `MCU.Module { uri: "..." }` and is listed in `ModuleFiles.files`.
- **Images**: referenced as `qrc:/assets/...` (path as listed in `ImageFiles`).
- **Animations**: `Behavior on <prop>` or explicit animations with `target` + `property`; set `running: true` for Sequential/Parallel animations.
- **Numbers to text**: `"" + value` (keep JavaScript simple).

## Clean code rules

- Pages never talk to CAN or BLE. Pages → singletons only.
- One component per file, file name = type name, `id` = short lowercase name.
- Property order: `id`, custom properties, geometry, visual, behaviours, children.
- No magic numbers in pages: use `Theme.*`.
- Every new C++ decode function gets a host unit test.
- `qul_lint.py` and host tests must pass before commit.
