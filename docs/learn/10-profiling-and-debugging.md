# 10 — Profiling and debugging

The method in this chapter is worth more than any individual fact in the
others, because it is what you fall back on when the facts run out.

## The method

> **Measure before you assert.**

Three times in one project I reasoned confidently to a wrong conclusion and
burned a build round each time:

- *"`ModuleFiles` makes a dependency's images visible."* It does not.
- *"`focus: true` is why nothing renders."* It was not; the user said so and
  was right.
- *"A font's `pixelSize` can be read back, like `colour.r`."* It cannot —
  `Type font does not have a property pixelSize for reading`.

And once with a measurement that was too loose: a mirror-symmetry test using
*mean* pixel difference said forty layers were symmetric and 4.8 MB was there
for the taking. The *max* difference said four layers and 570 KB. One of those
numbers would have shipped visible damage.

The lesson is not "be careful". It is that a cheap measurement beats an
expensive argument, almost always, and that **the measurement has to be the
right one**.

## The desktop build is not evidence

Worth repeating here because it is where debugging goes wrong first.

| | Desktop shim | Device |
|---|---|---|
| Queued events | delivered **synchronously** | real queue, **drops on overflow** |
| Memory | zero-initialised | dirty |
| Property reads | resolved immediately | through the dirty list |
| Binding loops | **detected and broken, with a warning** | no detector — hangs |
| Images | scaled freely | drawn at their own size |

A green desktop run means your QML parses and your logic is roughly right. It
says nothing about memory, timing or the renderer.

## Finding a freeze with gdb

The Qt desktop platform build (`QUL_PLATFORM=Qt`) is an ordinary native binary.
You can debug it like one, and that is the fastest path to a freeze that only
reproduces there.

```
gdb ./EVBikes
(gdb) run
# ...wait for the freeze...
# Ctrl+C
(gdb) set pagination off
(gdb) bt 60
```

### Reading the backtrace

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
#59 main
```

Three things to read off it:

**Is the stack deep or flat?** This one bottoms out in `main` at frame 59 —
**flat**. Not runaway recursion; a loop that is not making progress. A real
binding loop would show the same few frames repeating thousands of times.

**Where is it looping?** `DirtyList::process` is a `while the list is not
empty` loop. Sitting inside it means the list is being refilled as fast as it
drains.

**Is the frame advancing?** `Application::update (timestamp=133)`. Sample
again later; if `timestamp` is still 133, the engine never finished that frame.

### Make the frame boundary explicit

```
(gdb) b Qul::Private::Application::prepareFrame
(gdb) c
```

- Hits immediately → frames are completing; your problem is **speed**.
- Never hits → stuck inside one frame; your problem is a **loop**.

That one bit of information splits the search space in half, and it takes
thirty seconds.

### Sample more than once

Two samples is a measurement; one is an anecdote. In the case above, two
samples showed:

- different `Text` objects (`0xa79ce4`, then `0xa79804`) → cycling delegates,
  not stuck on one
- different `Math.floor` arguments (95.2, then 105.5) → **the animated value
  was still moving while the frame was being assembled**

That second observation *was* the diagnosis. No amount of reading the QML
would have produced it.

## Tracing when gdb is not available

On a board, printf tracing earns its keep — if it names the stage, not the
event:

```cpp
#define EVB_TICK(stage) do { if (g_traceTick <= 40) { \
    std::printf("[tick %u] " stage "\n", g_traceTick); std::fflush(stdout); } } while (0)

    EVB_TICK("enter");
    step(elapsedMs);          EVB_TICK("after step");
    advanceRuntime(elapsedMs); EVB_TICK("after advanceRuntime");
    Backend::periodic(now());  EVB_TICK("after periodic");
    EVB_TICK("done");
```

**The last line printed names the call that did not return.** That is the
whole value. Cap the count so a healthy run does not drown the console.

The output that cracked this project's freeze was four lines long:

```
[tick 2] after periodic
[tick 2] done
            ← nothing, ever again
```

Tick 2 done, then silence. The tick body completed, so the problem was after
it, in the frame. That pointed straight at the renderer and away from the
backend, where three days had already gone.

## Qt's own profiling

| Tool | What it gives |
|---|---|
| `QulPerf` (`QtQuickUltralite.Extras`) | Programmatic access to performance counters |
| `QulPerfOverlay` (`QtQuickUltralite.Profiling`) | On-screen FPS and frame timing |
| `QUL_ENABLE_PERFORMANCE_LOGGING` | Frame times, repaint counts, heap and stack peaks to the console |

Build with the define and the engine reports itself. If the overlay says
profiling is unavailable on your platform, the printf method above is the
fallback and it is not much worse.

## A worked example of the method

The problem: the device stops after exactly two runtime ticks. The desktop
build runs forever.

1. **Trace the tick stages.** → both ticks complete; the freeze is after the
   tick, not inside it.
2. **Form a hypothesis and test it.** Tick 2 is the first `periodic()`, which
   clears the stale flags, which grows a `Repeater` model. That is a documented
   rule violation. Fixed it. → **still stops at tick 2.** Hypothesis wrong, and
   the fix was still correct to keep.
3. **Stop guessing. Attach gdb.** Flat stack inside `DirtyList::process`,
   `timestamp` frozen at 133.
4. **Second sample.** Different delegate, different animated value. The value
   is moving *inside* the frame.
5. **Name the mechanism.** A `Behavior` on a bound property, re-triggered on
   every read. One binding chain, nine instances, every relayout.
6. **Fix and verify.** Assign instead of bind.

Steps 1 and 2 took days. Steps 3 to 5 took twenty minutes. The difference was
not cleverness — it was switching from arguing to looking.

## Check it yourself

Next time something hangs, before forming any theory:

```
gdb ./your-binary
(gdb) run
# Ctrl+C when it stops
(gdb) set pagination off
(gdb) bt 60
(gdb) b <RenderEngine>::prepareFrame
(gdb) c
```

Then read the three things: deep or flat, which loop, is the timestamp moving.

## Sources

- [Qt Quick Ultralite performance logging](https://doc.qt.io/QtForMCUs/qtul-performance-logging.html)
- [QulPerfOverlay](https://doc.qt.io/QtForMCUs/qtul-qmltypes.html)
