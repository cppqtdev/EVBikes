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
| `Text.contentWidth` / `contentHeight` | A `Text` with no `width` set is exactly as wide as its text: read its `width` |
| `parent.<custom property>` | `parent` is typed as a plain `Item`: give the parent an `id` and read it through that |
| `ListModel` roles (`model.title`) | A `required property` in the delegate, or an `int` model with the values on the delegate |
| A model that switches between a `ListModel` and a count | One `int` model; hide the delegate with `visible` |
| A property named `on<Something>` | `on<X>:` is also how a signal handler is spelled: name it `active`, `activeColor`, … |
| `transform` / `rotation` / `scale` on `Item` or `Rectangle` | Only `Image`, `Text` and `StaticText` transform: draw it as art and tint with `ColorizedImage` |
| A binding on `font.family` / `pixelSize` / `bold` / `italic` | The static font engine needs a configuration resolvable at compile time: a literal, a binding to a **readonly** property, or `font:` bound between whole `Qt.font({...})` configurations |
| A component taking `fontSize` / `bold` / `italic` from its caller | One `property font`, which the caller sets with `Qt.font({...})` |
| Reading a font back (`someFont.pixelSize`) | A font can be built but not read: keep the size in its own property beside the font, and let `qul_lint` check the two agree |
| `font.weight` | The static font engine picks a face by family, `bold` and `italic`; the weight enum only compiles for the Monotype Spark engine |
| A ternary mixing an enum constant with an `int` property | Pass both through a typed function instead — the two types cannot be merged into one value |
| Declaring art `Alpha8` by its file name | The exporter checks the pixels: an image is Alpha8 only if every visible pixel is pure white. `sync_project_files.py` measures each file instead of matching names |
| The same image named from two modules | A module must declare every image its own QML names — it does **not** inherit a dependency's images — and no image may be declared twice, or the merged `qulrcc` keeps one and the other's `qul_rasterBuffer_*_handle` is never written. So one module names a given file: put the reference in a component there and use that component. `sync_project_files.py` fails if two modules name one image |
| A `Behavior` on a declared property that also carries a binding | Assign the property from a signal handler (`onValueChanged: shown = value`) and let the `Behavior` animate that. A dirty property's binding is re-run on **every read**; the `Behavior` catches that write and restarts, so any binding that reads the value refills the dirty list and `prepareFrame` never finishes. Desktop Qt caches the read and never shows it. `qul_lint` checks this |
| One PNG shown at several sizes | One PNG per size, built from a vector master. An image is drawn at its own size, so a 40 px telltale shown at 24 px is resampled by a fraction and the thin strokes go. `assets/icons/src/<name>.<sizes>.svg` plus `tools/build_icons.py` builds them, in pure white so the Alpha8 path still applies |
| `Control` just for `background:` | A `Rectangle` child behind the rest — `import QtQuick.Controls` is remapped to `QtQuick.Controls.StyleDefault`, which a module only gets through `MCU.qulModules` and which costs flash |

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
- `qul_lint.py` and host tests must pass before commit. It also runs
  `qul_types.py`, which checks every property assigned and every `id.member`
  read against the members Qt for MCUs actually has — the desktop build accepts
  far more than the MCU compiler does, so this is what catches the difference
  before a build round does.
