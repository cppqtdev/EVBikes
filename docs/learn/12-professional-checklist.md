# 12 — The professional checklist

What separates someone who can make Qt for MCUs work from someone a team wants
on an embedded HMI programme.

## The four levels

### Level 1 — It builds and runs

You can write QML inside the subset, expose a C++ singleton, get it on a
desktop platform and on a board.

- [ ] Explain why Qt for MCUs compiles QML to C++, and what follows from it
- [ ] Name the five tools in the pipeline and say which one a given error
      came from
- [ ] Write QML that compiles first time — no `Canvas`, no `createObject`,
      no `Rectangle.border`, no `Text.contentWidth`
- [ ] Expose a `Qul::Singleton` with `Qul::Property` fields and read it in QML
- [ ] Set up a `.qmlproject` with modules, images and fonts
- [ ] Know that `ASM` belongs in `project(... LANGUAGES ...)`

### Level 2 — It survives the device

You stop being surprised by things that worked on desktop.

- [ ] Say out loud the four ways the desktop shim differs from the device
- [ ] Never put a `Behavior` on a bound property that another binding reads
- [ ] Keep every `Repeater` model constant
- [ ] Widen narrow integer types at the QML boundary
- [ ] Use `EventQueue` only for crossing a thread or ISR boundary — and know
      its capacity against what you post per tick
- [ ] Give every image one file per displayed size
- [ ] Know that a font configuration must resolve at compile time, and that a
      font cannot be read back

### Level 3 — You own the budget

You can be handed a memory limit and meet it with numbers rather than hope.

- [ ] Say where every byte lives: flash, SRAM, VRAM
- [ ] Compute a layer buffer from the formula, for OTF and for double buffered
- [ ] Know the 15× difference between those two, and defend staying on OTF
- [ ] Measure decoded image cost, not just file size
- [ ] Know when Alpha8 applies, and decide it by **looking at the pixels**
- [ ] Find art that is reachable only from dead code
- [ ] Count your font configurations and know what the big sizes cost
- [ ] Choose a `resourceCachePolicy` per build profile and say why
- [ ] Set the text cache rather than paying the 192 KB default
- [ ] Know what `Shapes` costs in VRAM before using it

### Level 4 — You are trusted with the programme

- [ ] Find a freeze with gdb in twenty minutes instead of arguing for days
- [ ] Design a safety-critical split, and know what the certification does and
      does not cover
- [ ] Check telltales against UNECE R121 rather than against taste
- [ ] Generate project files instead of maintaining them
- [ ] Write a lint rule for every rule the team keeps forgetting
- [ ] Say "I measured it and I was wrong" without it costing you anything

That last one is not filler. It is the single habit that most changes how fast
a team moves.

## A twelve-week path

Assumes you know Qt Quick already and have a board or the desktop platform.

| Weeks | Do this | Done when |
|---|---|---|
| 1–2 | Build the Qt examples. Read chapters 1–3. Port a small Qt Quick screen and fight the subset | You can predict which of your QML will not compile |
| 3–4 | Chapter 5. Expose a backend singleton with properties, a signal and an event queue. Unit-test a decoder on the host | Data flows C++ → QML and you tested the decode without a board |
| 5–6 | Chapters 4 and 10. Deliberately write a binding loop and find it with gdb. Add performance logging | You have read your own backtrace and understood it |
| 7–8 | Chapter 6. Audit your images: decoded totals, Alpha8, per-size files, trimming | You cut the image cache measurably and the UI looks the same or better |
| 9–10 | Chapters 7–9. Write the memory budget. Count font configurations. Compute the layer buffer | You can defend every number in your budget |
| 11–12 | Chapter 11. Split safety-critical from the rest. Check symbols against R121 | You know what would be on screen if the UI stack hung |

## The ten things that cost the most time

From one real project, in the order they hurt:

1. **A `Behavior` on a bound property.** Froze the device after two ticks.
   Desktop ran forever. Days.
2. **A `Repeater` model that changed at runtime.** Documented, invisible on
   desktop.
3. **An `EventQueue` holding five while eight were posted per tick.** Three
   dropped silently, every tick.
4. **Narrow integer types mirrored into the desktop bridge.** Every number on
   screen was garbage; 8- and 32-bit were fine, 16-bit was not.
5. **Unsigned wraparound in a timeout check.** Every node declared dead,
   several times a second.
6. **An image declared in two modules.** Built fine, failed at link with an
   undefined raster handle.
7. **`ASM` missing from `project()`.** Resource and glyph blobs silently
   dropped.
8. **One icon shown at five sizes.** Everything looked cheap and nobody could
   say why.
9. **Eleven images kept alive by a function with no callers.** 1.96 MB of
   cache for pictures never drawn.
10. **A circle drawn as an ellipse.** Shipped for months. One line of
    measurement found it.

Notice how many are invisible on desktop, and how many were found by measuring
rather than reading.

## Questions a good interview asks

- Why does Qt for MCUs have no `Component.createObject`?
- Your UI freezes on the board and runs fine on desktop. First three steps?
- An image is 16 KB on disk. How much RAM does it need? What else do you need
  to know?
- When is a `Behavior` unsafe?
- Where does a `Repeater`'s memory come from?
- You need 200 KB of VRAM back. Where do you look, in what order?
- What does Qt Safe Renderer's certification actually cover?
- Your 24 px icons look soft. Why, and what is the fix?

If you can answer those from measurement rather than recall, you are past the
hard part.

## The habit, one more time

Every chapter here ends with **Check it yourself**, and that is the whole
point of the guide. Qt for MCUs punishes assumption more than most frameworks,
because the thing you assume — that memory is elastic, that the renderer will
cope, that desktop behaviour transfers — is exactly what it removed.

A cheap measurement beats an expensive argument. And when the measurement
disagrees with you, it is right.
