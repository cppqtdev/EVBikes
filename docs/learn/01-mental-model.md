# 01 — The mental model

> Qt Quick Ultralite is not Qt Quick made smaller. It is a different engine that
> accepts a subset of the same language.

Hold that sentence. Nearly every surprise in the rest of this guide follows from
people assuming the opposite.

## What is actually different

Qt Quick on desktop is an interpreter plus a scene graph plus a JavaScript
engine, allocating as it goes. Qt Quick Ultralite **compiles your QML to C++ at
build time**. There is no QML file on the device, no parser, no JavaScript
engine, and — this is the one that bites — **no dynamic allocation** in the
normal path.

That single change explains most of the subset:

| Desktop Qt Quick | Qt for MCUs | Why |
|---|---|---|
| QML parsed at startup | QML compiled to C++ by `qmltocpp` | No parser on the device |
| Objects created on demand | Objects laid out statically at build time | No heap |
| Full JavaScript | A small expression subset | No JS engine |
| `Component.createObject()` | Nothing equivalent | No dynamic creation |
| A `Repeater` grows and shrinks | Delegates pre-allocated from a compile-time estimate | No heap |
| Images decoded on demand | A fixed resource set with a cache policy you choose | Known memory |
| Fonts rasterised at runtime | Glyphs rasterised at build time (static engine) | No font heap |

Look at the right-hand column. It is the same reason eleven times. **There is no
heap, so everything must be countable at build time.**

## The consequence you will feel first

Your application's entire object tree is one big statically allocated
structure. In a backtrace it shows up as literally that:

```
self=0x88fe88 <main::item+181960>
```

`main::item` is the root. Everything is an offset inside it. Nothing was
allocated; it was all laid out by the compiler.

This is why a `Repeater` whose model grows at runtime is not slow — it is
**undefined**. There is nowhere for the new delegate to come from. On desktop
the same QML is fine, which is exactly what makes it dangerous.

## The three memories

Desktop Qt has "memory". An MCU has three, and they behave nothing alike. This
is the distinction to internalise early; chapter 7 does it properly.

- **Flash** — where the program and the resources live. Large, read-only,
  slow. Your compiled QML, your images, your glyphs.
- **SRAM** — the working memory. Small. Stack, your C++ state, the engine's
  bookkeeping.
- **VRAM / framebuffer memory** — what the display controller reads. Often the
  tightest of the three, and often on a different bus with different rules.

A change can move cost *between* these and look like a saving when it is not.
Compressing an image makes flash smaller and makes the decoded cache no smaller
at all, because it is decompressed to use it. Chapter 6 has the numbers.

## The desktop build lies to you

Qt for MCUs ships a desktop platform (`QUL_PLATFORM=Qt`) and most teams also
keep a plain Qt 6 build for fast iteration. Both are enormously useful and both
will tell you your application works when it does not.

Measured in this project, the desktop shim differs from the device by:

- delivering queued events **synchronously**, so a full `Qul::EventQueue` never
  drops anything and you never find out your queue is too small;
- zero-initialising memory the device leaves dirty;
- resolving property reads immediately rather than through the dirty list;
- **detecting binding loops and breaking them with a warning** — the device has
  no detector, so the same loop just recurses until the frame never ends.

That last one cost real days. The desktop build ran happily at 40+ ticks; the
device stopped after exactly two, every time. Chapter 4 has the full story and
chapter 10 has the method that found it.

> **The rule:** the desktop build passing is not evidence the device works. It
> is evidence that your QML parses and your logic is roughly right. Nothing
> about memory, timing or the renderer transfers.

## What you keep

It is worth saying what is *not* lost, because the subset reads as scarier than
it is in practice.

- Declarative QML with property bindings, states and transitions
- Animations, including `Behavior`, `NumberAnimation`, `SequentialAnimation`
- `Item`, `Rectangle`, `Text`, `Image`, `Row`, `Column`, `Repeater`, `PathView`
- `QtQuick.Shapes` for vector paths, as a separate module you opt into
- A C++ bridge that is genuinely pleasant — see chapter 5

You can build a real, animated, good-looking HMI. This cluster has a hexagonal
gauge with a sweeping needle, animated telltales, a live map and a dozen
screens. None of that needed an escape hatch.

## Check it yourself

Find the generated C++ for one of your QML files and read it. Nothing makes the
model concrete faster than seeing your own bindings as functors:

```
find build -name "*.cpp" -path "*ClusterComponents*" | head
```

Open one. Look for `_<property>_binding` and the `bindingFunctor` structs. That
is your QML, compiled.

## Sources

- [Qt for MCUs — reference overview](https://doc.qt.io/QtForMCUs/qtul-reference-overview.html)
- [Qt Quick Ultralite QML types](https://doc.qt.io/QtForMCUs/qtul-qmltypes.html)
