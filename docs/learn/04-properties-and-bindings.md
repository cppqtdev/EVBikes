# 04 — Properties and bindings

This is the chapter that will save you the most time, because the binding
engine is where Qt for MCUs differs from desktop Qt in a way that is invisible
until it is catastrophic.

## How a frame is built

Roughly, each frame:

1. `Application::update(timestamp)` is called
2. → `repaint()` → `prepareFrame()`
3. → `qulEmitChangeEvents()` → `ChangeEventBase::emitChangeEvents()`
4. → **`DirtyList::process()`** — walks the list of dirty change events, calling
   each one's handler
5. the handlers re-evaluate bindings, which may dirty more things
6. when the list drains, the frame renders

Step 4 is the one to hold on to. It is a `while the list is not empty` loop.
**If handling a dirty item puts something back on the list, the loop never
drains and the frame never finishes.**

There is no iteration cap and no loop detector.

## Desktop Qt has a safety net. This does not.

Desktop Qt detects binding loops and breaks them with
`QML Binding loop detected for property "x"`. Qt for MCUs has no such check.
The same loop simply recurses, or re-fills the dirty list, until the
application hangs or the stack runs out.

This is the single most important difference in the whole engine. A loop that
desktop Qt reports as a warning is, on the device, a hang.

## The trap: `Behavior` on a bound property

This is correct, ordinary Qt Quick:

```qml
property real shown: value          // a binding
Behavior on shown {                  // and an animation on it
    NumberAnimation { duration: 200 }
}
```

On Qt for MCUs it is a hang, **if anything reads `shown` inside another
binding**.

Why: Qt for MCUs re-runs a dirty property's binding **on every read**. The
`Behavior` intercepts that write and restarts the animation, which produces a
new value and marks the property dirty again. The next read re-runs the
binding, and round it goes.

In this project `shown` fed a chain — `shownValue` → `used` → `drawn` →
`blanks` → each digit's `text` — and every one of nine readouts relaughed the
whole chain on every relayout. The device stopped after exactly two runtime
ticks, every single time. The desktop build ran to tick 40 and beyond, because
it caches the read.

### What the evidence looked like

A breakpoint on `prepareFrame` that never fired again, and a flat backtrace —
no deep recursion, just the same bindings over and over:

```
#0  Math::floor (v=95.2)
#1  NumberReadout::_used_binding
#7  NumberReadout::_drawn_binding
#13 NumberReadout::_blanks_binding
#19 NumberReadout::text_::_text_binding
#28 TextLight::relayout
#32 DirtyList::process
#35 Application::prepareFrame
#37 Application::update (timestamp=133)
...
#59 main
```

Two samples seconds apart showed `timestamp` still 133 and two *different*
`Text` objects — the loop was cycling the delegates, not stuck in one place.
And the `Math.floor` arguments differed between samples (95.2, then 105.5),
which is what proved the animated value was still moving **while the frame was
being assembled**. That was the whole diagnosis.

### The fix

A `Behavior` is for properties you **assign**, not properties that carry a
binding:

```qml
property real shown: 0
onValueChanged: shown = value
Component.onCompleted: shown = value
Behavior on shown {
    NumberAnimation { duration: 200 }
}
```

Now nothing re-runs on read. The animation writes `shown` once per frame and
the dirty list drains.

### Where else it hides

The same shape turned up in two more places in the same codebase, neither of
which had bitten yet because those screens had not been drawn:

```qml
property real routeLateral: map.lateral      // bound
Behavior on routeLateral { ... }             // and animated
// ...and read by three other bindings
```

The twenty-odd other `Behavior`s in the project were fine, and the difference
is precise: they animate `opacity`, `color`, `x`, `width` — **leaf visual
properties that no binding reads back**. Those settle in one pass.

> **The rule:** a `Behavior` on a declared property that also carries a binding
> is safe only while nothing reads that property inside another binding. Since
> you cannot guarantee that stays true, just don't do it. Assign instead.

`qul_lint.py` checks this now:

```
X.qml:3: Behavior on 'shown', which is bound at line 1; assign it from a
signal handler instead or the frame never finishes
```

## The quieter trap: reading a property inside its own change handler

```qml
// a binding that reads this item's own visibility, while a handler
// changes that visibility — the handler re-enters its own input
property bool ready: check.visible && somethingElse
onReadyChanged: check.visible = false
```

Desktop Qt warns. Here it recurses. The cure is the same: keep the condition
out of the binding, and gate the state where it belongs.

## Property reads are not free

A read of a dirty property executes its binding. A chain five deep executes
five functors. Inside a `Repeater` delegate that is per delegate, per frame.

The practical consequences:

- **Keep binding chains short.** `text` → `blanks` → `drawn` → `used` →
  `shownValue` → `shown` is five hops for one string, repeated per digit cell.
- **Prefer `readonly`** where the value is genuinely constant. It documents
  intent and lets the compiler treat it as fixed.
- **Don't recompute in a binding what a handler could assign once.**

## Assigned, not bound: the general pattern

The pattern that keeps coming back:

```qml
//  Assigned, not bound: a Behavior on a bound property that other bindings
//  read re-runs that binding on every read and the frame never finishes.
property real routeLateral: 0
onLateralChanged: map.routeLateral = map.lateral
Component.onCompleted: map.routeLateral = map.lateral
```

Three lines instead of one, and it cannot hang. Worth it.

One ordering detail: if one declared property derives from another, declare the
source **first**. Forward references within an object resolve at runtime on
desktop but are worth avoiding here, where a binding compiler is involved:

```qml
readonly property int guidanceTop: 92
readonly property int buttonsY: map.guidanceTop - 4   // declared after
```

## Check it yourself

Count your binding depth:

```
grep -n "readonly property\|property" qml/components/YourThing.qml
```

Find every `Behavior` on a declared property:

```
grep -rn "Behavior on" qml/ -B8 | grep -E "property |Behavior on"
```

And when a frame hangs, go straight to chapter 10. Reasoning about it is
slower than looking.

## Sources

- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
