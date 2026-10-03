# Qt for MCUs — a working engineer's guide

Twelve chapters, written against Qt for MCUs 2.12 and against one real cluster
that got built, broken and fixed with it.

Everything here is either quoted from the Qt documentation with a link, or
measured in this repository. Where something is an opinion it says so. Where
something was learned by getting it wrong, it says that too, because the wrong
turn is usually the part worth remembering.

The same material as a single browsable page, with the diagrams:
https://claude.ai/artifact/YKNqZUYixftWsNAkkxSHd7

## Who this is for

Someone who knows Qt Quick and now has to ship on a microcontroller. The hard
part is not learning new API. It is unlearning the assumptions that desktop Qt
lets you keep: that memory is elastic, that the renderer will cope, that a
binding is free, and that if it runs on your machine it runs on the board.

## The order to read it in

The chapters build on each other. If you only have an afternoon, read 1, 4 and
7 — the mental model, what a binding actually costs, and where the memory goes.
Those three are where most of the expensive mistakes live.

| # | Chapter | What you can do after it |
|---|---------|--------------------------|
| 01 | [The mental model](01-mental-model.md) | Say what Qt for MCUs removes and why, without guessing |
| 02 | [Toolchain and build](02-toolchain-and-build.md) | Read a build log and know which tool is complaining |
| 03 | [The QML subset](03-qml-subset.md) | Write QML that compiles the first time |
| 04 | [Properties and bindings](04-properties-and-bindings.md) | Explain why a frame never finished |
| 05 | [The C++ bridge](05-cpp-bridge.md) | Expose a backend to QML and know what crosses the line |
| 06 | [Images and resources](06-images-and-resources.md) | Cut image cost without touching the design |
| 07 | [Memory](07-memory.md) | Say where every byte lives: flash, SRAM, VRAM |
| 08 | [Layers and bits per pixel](08-layers-and-bpp.md) | Size a layer budget and defend the numbers |
| 09 | [Fonts and text](09-fonts-and-text.md) | Stop the font configurations multiplying |
| 10 | [Profiling and debugging](10-profiling-and-debugging.md) | Find a freeze instead of guessing at it |
| 11 | [Safety and certification](11-safety-and-certification.md) | Know what the functional-safety variant changes |
| 12 | [The professional checklist](12-professional-checklist.md) | Assess yourself honestly against the role |

## The one habit that matters

Measure before you assert.

This guide exists because that habit kept paying. A freeze that three rounds of
reasoning could not find took one `gdb` backtrace. A "symmetric" image set that
looked like a 4.8 MB saving turned out to be four files and 570 KB once the
right test was used. An icon that "looked wrong" was a circle drawn as an
ellipse, and the measurement said so in one line.

Every chapter ends with **Check it yourself** — the command or the script that
turns an opinion into a number. Use those before you believe anything in here,
including the parts I am confident about.

## A note on the examples

The worked examples come from an electric-motorcycle instrument cluster:
1280×480, Qt for MCUs 2.12.2, built for both the desktop Qt platform and
Infineon TRAVEO T2G. Paths like `qml/components/NumberReadout.qml` refer to that
project. The lesson generalises; the file name is there so you can go and look.
