# 03 — The QML subset

The subset is large enough to build a real HMI and small enough that you will
hit its edges in your first week. This chapter is the map of those edges.

## What you get

| Import | The types worth knowing |
|---|---|
| `QtQuick` | `Item`, `Rectangle`, `Text`, `TextInput`, `Image`, `BorderImage`, `Row`, `Column`, `Repeater`, `Loader`, `ListView`, `PathView`, `Flickable`, `MouseArea`, `Keys`, `Timer`, `Connections`, `Component`, `State`, `Transition`, `Behavior`, the animation family, the `Path*` family, `Rotation` / `Scale` / `Translate` / `Matrix4x4` |
| `QtQuick.Controls` | `Button`, `CheckBox`, `RadioButton`, `Switch`, `Slider`, `Dial`, `ProgressBar`, `SwipeView`, `Control` |
| `QtQuick.Layouts` | `RowLayout`, `ColumnLayout`, `GridLayout`, `Layout` |
| `QtQuick.Shapes` | `Shape`, `ShapePath`, `ShapeGradient`, `LinearGradient` |
| `QtQuick.Timeline` | `Timeline`, `TimelineAnimation`, `Keyframe`, `KeyframeGroup` |
| `QtQuickUltralite.Extras` | `ColorizedImage`, `StaticText`, `AnimatedSpriteDirectory`, `PaintedItem`, `QulPerf` |
| `QtQuickUltralite.Layers` | `Application`, `ApplicationScreens`, `Screen`, `ItemLayer`, `ImageLayer`, `SpriteLayer` |
| `QtQuickUltralite.SafeRenderer` | `SafeImage`, `SafePicture`, `SafeText` |

Everything past `QtQuick` and `Extras` has to be switched on:

```qml
ModuleFiles { MCU.qulModules: ["Shapes", "Controls"] }
```

and each one costs flash, so list only what you draw with.

## What is missing, and what to do instead

### Structural

| Missing | Instead |
|---|---|
| `Window`, `ApplicationWindow` | A root `Rectangle` or `Item` |
| `Grid`, `Flow`, `GridView` | `Row` + `Column`, or plain `x` / `y` |
| `Qt.createComponent`, `createObject` | Static items, `Loader`, `Repeater` |
| `StackView`, `Popup` | `Loader` plus `visible` |
| `Loader.item` access | Share state through a singleton instead |
| `States` with `when:` | Plain property bindings — `when` has known problems |

### Visual

| Missing | Instead |
|---|---|
| `Canvas`, shaders, `MultiEffect`, `DropShadow`, `Glow` | Pre-render a PNG and tint it with `ColorizedImage` |
| `Rectangle.border` | A `Rectangle` behind, or a thin `Rectangle` as a line |
| Per-corner radii | One `radius` for all four |
| `transform` / `rotation` / `scale` on `Item` or `Rectangle` | Only `Image`, `Text` and `StaticText` can be transformed. Draw it as art and tint it |
| `Text.contentWidth` / `contentHeight` | A `Text` with no `width` set is exactly as wide as its text — read its `width` |

### Data

| Missing | Instead |
|---|---|
| `ListModel` roles (`model.title`) | A `required property` in the delegate, or an `int` model with the values on the delegate |
| A model that switches between a `ListModel` and a count | One `int` model; hide delegates with `visible` |
| `JSON`, `XMLHttpRequest`, heavy JavaScript | Do it in C++ |

## The JavaScript subset

There is no JavaScript engine. Expressions are translated to C++, so what
survives is what translates:

- **No** arrays, object literals, `let` / `const`, arrow functions, template
  literals, closures
- `Math.min` and `Math.max` take **two** arguments, not a list
- A limited set of `String` methods — `String.length` is not among them
- `var` is fine inside a function body; the type is inferred

Counting digits is the standard example, since `String.length` is gone:

```qml
readonly property int used: {
    var rest = Math.abs(shownValue)
    var count = 1
    while (rest >= 10) {
        rest = Math.floor(rest / 10)
        count = count + 1
    }
    return count
}
```

Function parameters and return values **must be typed**:

```qml
function digitAt(value: int, position: int) : string { ... }
```

## Four traps that cost real time

### `parent` is a plain `Item`

`parent` is typed as `Item`, not as the actual parent type. Reading a custom
property through it does not compile:

```qml
// no — parent is an Item and has no `highlight`
color: parent.highlight ? "red" : "grey"
```

Give the parent an `id` and go through that.

### A property may not be called `on<Something>`

`on<X>:` is also how a signal handler is spelled, so a property named
`onColour` collides. Name it `activeColour`.

### A ternary may not mix an enum with an int

```qml
// no — the two types cannot be merged into one value
source: active ? NavigationData.Straight : someIntProperty
```

Pass both through a function with a declared return type.

### Fonts are compile-time configurations

The static font engine needs every font configuration resolvable at build time.
That has three consequences:

```qml
// no — a binding on a subproperty
font.pixelSize: someProperty

// yes — a literal
font.pixelSize: 22

// yes — the whole font, bound between complete configurations
font: active ? Theme.bigFont : Theme.smallFont   // both readonly Qt.font({...})
```

A component that wants a caller-chosen font takes **one `property font`**, and
the caller passes `Qt.font({ family: ..., pixelSize: ..., bold: true })`.

And a font **cannot be read back**. `someFont.pixelSize` does not compile —
`Type font does not have a property pixelSize for reading`. If you need the
size as a number, keep it in its own property beside the font:

```qml
property int  digitSize: 24
property font digitFont: Qt.font({ family: Theme.fontFamily, pixelSize: 24 })
```

and have a lint rule check the two agree, because nothing else will.

`font.weight` is also out. The static engine picks a face by family, `bold` and
`italic`; the weight enum compiles only for Monotype Spark.

## The one that is not a compile error

Everything above fails the build, which is the kind thing. This one does not:

> **A `Repeater`'s delegates are pre-allocated from a compile-time estimate.
> The model must not change while the application runs.**

```qml
// works on desktop; undefined on the device
Repeater { model: PhoneListData.contactCount }

// correct
Repeater {
    model: 3
    MessageRow { visible: index < PhoneListData.contactCount }
}
```

There is no heap, so there is nowhere for a new delegate to come from. The
desktop build creates them on demand and never complains.

## Lint it, don't remember it

None of this stays in anyone's head. A lint that knows the member tables
catches it in a second instead of a build round. This project has
`tools/qul_lint.py` and `tools/qul_types.py` checking:

- every property assigned and every `id.member` read against the members Qt for
  MCUs actually has
- untyped function parameters
- `font.weight`
- bindings on font subproperties
- reading a font back
- `digitSize` disagreeing with its font's `pixelSize`
- ternaries mixing an enum with an int
- a `Behavior` on a property that also carries a binding (chapter 4)

That list grew one entry per mistake. That is the right way for it to grow —
every rule in it is there because something failed once.

## Check it yourself

Put a deliberate error in — read a custom property through `parent`, or bind
`font.pixelSize` — and watch which tool complains and what it says. Knowing
the shape of each message is worth more than memorising the table.

## Sources

- [Qt Quick Ultralite QML types](https://doc.qt.io/QtForMCUs/qtul-qmltypes.html)
- [Text rendering and fonts](https://doc.qt.io/QtForMCUs/qtul-fonts.html)
