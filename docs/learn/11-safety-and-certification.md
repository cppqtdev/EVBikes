# 11 — Safety and certification

If you build clusters, medical displays or industrial panels, this chapter is
the difference between a demo and a product. If you build consumer devices,
skim it once so you recognise the vocabulary when a customer uses it.

## The problem a safe renderer solves

Some things on a screen are **legally required to be correct**. A brake
warning lamp, a tyre pressure warning, an ABS telltale. If the UI stack
crashes, hangs or draws the wrong thing, those must still be right — or the
driver must at least not be told everything is fine when it is not.

You cannot get there by making the whole UI stack safety-certified. A full
HMI is too large and changes too often. The answer is to separate a small
**safety-critical** part from a large **non-critical** part, certify only the
small part, and monitor it.

## Qt Safe Renderer

Qt Safe Renderer is a **separate component** that runs alongside Qt Quick
Ultralite. It renders the safety-critical items itself and verifies the output
rather than trusting the main UI stack.

The certification, for Qt Safe Renderer 2.2:

| Standard | Level |
|---|---|
| ISO 26262:2018-6 | **ASIL D** |
| ISO 26262:2018-8 §11 | ASIL D |
| IEC 61508:2010-3 | SIL 3 |
| EN 50128:2011 6.7.4 | SIL 4 (railway) |
| ISO 25119-3 AMD 1:2020 | agriculture / forestry |
| IEC 62304:2015 | Class C (medical) |

Read the scope line carefully, because it is the part people misread:

> The certification covers **all the content inside the `SafeRenderer`
> namespace** — the certified runtime that executes on the target. The
> implementation of the safety requirements and the certification concern
> **only the Qt Safe Renderer module itself**.

**Your application is not certified because you linked it.** Your telltales
are rendered and verified by a certified component; your own code, your build
process and your system design are still yours to argue for.

## The safe QML types

From `QtQuickUltralite.SafeRenderer`:

| Type | For |
|---|---|
| `SafeImage` | A safety-critical image — a telltale |
| `SafePicture` | A safety-critical picture |
| `SafeText` | Safety-critical text |

They look like their ordinary counterparts and behave differently underneath:
their output is monitored by Qt Safe Renderer's **output verification**, which
checks that what reached the framebuffer is what was asked for.

### Constraints worth knowing before you design

- **The root element needs fixed dimensions** — offsets are computed from it.
- Each safe item needs an `objectName`, `width`, `height` and `fillColor`.
- **Safe items do not support rotation.**
- An invisible safe item still appears as a **visible rectangle**, which is a
  deliberate fail-safe, not a bug. A parent that is invisible still draws its
  safe children.
- Framebuffer formats: RGB565, RGB888, ARGB8888.
- Build setup: `QSR_TOOLS_DIR` pointing at Qt Safe Renderer Tools, and the
  right CRC algorithm in `BoardDefaults.qmlprojectconfig`.

That rotation limit and the visible-when-invisible rule shape the layout. Plan
for them at design time, not when you are retrofitting.

## Where this meets the regulations

Qt Safe Renderer makes sure the lamp you drew is the lamp that reached the
glass. It has nothing to say about whether you drew the **right** lamp. That
is a different body of rules, and for a road vehicle it is not optional.

| | |
|---|---|
| **UNECE Regulation No. 121** | The UN rule for controls, tell-tales and indicators. The official symbol drawings are in its annex and the PDF is **free** |
| **ISO 2575** | *Road vehicles — Symbols for controls, indicators and tell-tales.* The standard R121 draws from. Paid |
| **ISO 7000 / IEC 60417** | The symbol database, as `.eps`, `.ai` and `.dwg` drawing files. A yearly subscription; free to browse |

Three things learned redrawing a cluster's telltales against these:

- **The shapes are specified, not designed.** An engine-malfunction lamp has
  a defined form. Drawing something else that "means the same" is a finding at
  type approval.
- **Getting it wrong is easy and invisible.** In this project the
  engine-malfunction lamp was drawn as an **oil can** — which is the oil
  pressure symbol — and the brake warning was a power symbol in brackets
  instead of the specified exclamation. Both had been shipping in the design
  for months. Nobody noticed because each looked plausible alone.
- **Check against R121 even if you are buying art.** A commercial icon pack is
  drawn to look right, not to be approved.

## A practical split

```
┌──────────────────────────────────────────────────────────┐
│  Non-critical: the whole HMI                             │
│  menus, media, navigation, trip data, animation          │
│  Qt Quick Ultralite                                      │
├──────────────────────────────────────────────────────────┤
│  Safety-critical: a handful of items                     │
│  brake, ABS, airbag, tyre pressure, high beam, indicators│
│  SafeImage / SafeText, verified by Qt Safe Renderer       │
└──────────────────────────────────────────────────────────┘
```

Keep the critical set **small and boring**. Every item you add is something
that must be argued for, and arguing is more expensive than drawing.

## Non-safety hygiene that still matters

Even with no certification in scope, the habits are the same ones:

- **Pages never touch the bus.** Pages read singletons; decoders own the
  protocol. One boundary, testable on both sides.
- **Host unit tests for every decode function.** Bit packing is miserable to
  debug on a board and trivial to test on a desktop.
- **Stale means stale.** When a node stops talking, show that — dashes, not
  the last value. Claiming the bike is doing 52 because that is what it said
  before the bus went quiet is the dangerous failure.
- **Watch for unsigned wraparound in timeout checks.** This project declared
  every node dead, repeatedly, because a timestamp one millisecond ahead of
  the comparison time wrapped to four billion:

  ```cpp
  // nowMs was sampled before step(), which then stamped frames with a
  // later time. nowMs - frameTime wrapped. Read the clock again.
  Backend::periodic(evb::platform::millis());
  ```

- **Clamp the elapsed time in a tick.** A long first frame should not advance
  the state machine by two seconds:

  ```cpp
  const uint32_t gap = nowMs - m_lastTickMs;
  const uint32_t elapsed = gap > kMaxTickMs ? kMaxTickMs : gap;
  ```

## Check it yourself

Download [UNECE R121](https://unece.org/fileadmin/DAM/trans/main/wp29/wp29regs/R121r1e.pdf)
and compare your telltales against the annex, one by one. It takes an hour and
it is the cheapest review in the whole programme.

Then ask of each safety-critical item: if the main UI stack hung right now,
what would the driver see?

## Sources

- [Qt Quick Ultralite application with safety-critical items](https://doc.qt.io/QtForMCUs/qtul-qul-app-with-safety-critical-items.html)
- [Qt Safe Renderer — delivery and certification](https://doc.qt.io/QtSafeRenderer/qtsr-delivery.html)
- [Safe Renderer QML types](https://doc.qt.io/QtForMCUs/qtquickultralite-saferenderer-qmlmodule.html)
- [UNECE Regulation No. 121](https://unece.org/fileadmin/DAM/trans/main/wp29/wp29regs/R121r1e.pdf)
- [ISO 2575](https://www.iso.org/standard/68409.html)
