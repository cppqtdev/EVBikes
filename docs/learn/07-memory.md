# 07 — Memory

Desktop Qt has "memory". An MCU has three kinds, each with its own size, speed
and failure mode. Knowing which one a change affects is most of the skill.

## The three

```
┌─────────────────────────────────────────────────────────────────┐
│ FLASH            internal + external, read-only, large, slow    │
│   compiled QML (your bindings, as C++)                          │
│   image resources                                               │
│   glyph data (static font engine)                               │
│   program code                                                  │
├─────────────────────────────────────────────────────────────────┤
│ SRAM             small, fast, read-write                        │
│   the static object tree  (main::item — all of it)              │
│   stack  (per task under an RTOS)                               │
│   your C++ state, decoders, queues                              │
│   engine bookkeeping: dirty lists, change events                │
├─────────────────────────────────────────────────────────────────┤
│ VRAM             what the display controller reads              │
│   layer buffers / line buffers                                  │
│   command buffers                                               │
│   image cache (if the policy caches)                            │
│   text cache  (192 KB by default)                               │
│   vector graphics buffers (if Shapes is enabled)                │
└─────────────────────────────────────────────────────────────────┘
```

A change can move cost between these and look like a win when it is not:

| Change | Flash | SRAM | VRAM |
|---|---|---|---|
| Compress an image | ↓ | — | **unchanged** |
| Alpha8 instead of ARGB8888 | ↓ | — | ↓ ×4 |
| Trim a transparent border | ↓ | — | ↓ |
| `resourceCachePolicy: NoCaching` | — | — | ↓ |
| Bpp24 instead of Bpp32 | — | — | ↓ 25% |
| Another font size | ↑ | — | — |
| An extra layer | — | — | ↑ |

The compression row is the one that fools people. Compressed images are
decompressed into the cache to be drawn, so the cache cost is identical.

## SRAM: the static object tree

Your entire QML object tree is one statically allocated structure. In a
backtrace it looks like this:

```
self=0x88fe88 <main::item+181960>
binding at 0x8906a8 <main::item+184040>
```

Everything is an offset in `main::item`. Nothing is allocated.

Practical consequences:

- **Every QML item costs SRAM whether visible or not.** A `Loader` with
  `active: false` is the way to not pay for a screen.
- **A `Repeater` costs its full model count**, always.
- **Properties cost.** Each `Qul::Property` carries value plus binding
  bookkeeping. This is a real reason not to add a property purely to drive
  UI state when an existing one would do.

## SRAM: the stack

Easy to forget and nasty when it bites. Under FreeRTOS each task has a fixed
stack, and the UI task has to hold the deepest binding chain.

Deep binding chains are deep **call** chains. The hang in chapter 4 had a flat
stack, which is what proved it was a dirty-list loop rather than runaway
recursion — but a genuine binding loop *does* eat the stack, and the symptom
is a hard fault with no useful backtrace.

Watch the high-water mark. Qt's performance logging reports it; so does
FreeRTOS's `uxTaskGetStackHighWaterMark`.

## VRAM: the four consumers

### 1. Layer buffers

Usually the largest. Chapter 8 does this properly. The short version, for a
1280-wide screen in on-the-fly mode:

```
WIDTH × LINE_BUFFER_HEIGHT × BPP  +  command buffer
```

| line buffer | 32 bpp | 24 bpp |
|---|---|---|
| 32 | 163,840 | 122,880 |
| 64 | 327,680 | 245,760 |
| 128 | 655,360 | 491,520 |

Double-buffered instead, the same screen is `1280 × 480 × 2 × 4` = **4.9 MB**.
Staying on OTF is worth more than every other saving in this guide combined.

### 2. The image cache

Governed by `resourceCachePolicy` and capped by `maxResourceCacheSize`. With
`NoCaching` and resources in external flash it is zero. Otherwise it is the
decoded total from chapter 6 — the 12.77 MB number, not the 759 KB one.

### 3. The text cache

**192 KB by default**, in VRAM. Configurable:

```cpp
#include <qul/application.h>

Qul::ApplicationConfiguration config;
config.setTextCacheSize(96 * 1024);
Qul::Application app(config);
```

`Qul::ApplicationConfiguration` lives in `qul/application.h` — not in a header
of its own — and has existed since Qt Quick Ultralite **2.1**. It is passed to
the `Application` **constructor**, not set statically.

I got this wrong once by inventing a header name from a documentation page for
a newer release, which broke the build outright. The class was right; the
include was fiction. Check the header before you trust a snippet, including
this one:

```
grep -rn "class ApplicationConfiguration" $QUL_DIR/include/qul/
```

With the static font engine the glyphs are in flash, so the cache holds only
the text that changes. Cutting it is usually safe — and it fails **loudly**,
so bisect it on hardware rather than guessing upward.

### 4. Vector graphics buffers

Only if `Shapes` is enabled:

- global alpha buffer, default 320×320 at 4bpp ≈ **51 KB**
- global path buffer, default **32 KB**
- per-path mask buffers, allocated on demand

Together about **83 KB** for the privilege of drawing vector paths. Worth
knowing before you reach for `Shape` to draw something a tinted PNG could do.
In this project four files used `Shape`, and one of them drew a route that
another screen already drew with images — the same job, twice, one of them
costing 83 KB of VRAM.

## A worked budget

This cluster, 1280×480, after a round of work:

```
241 images referenced   flash 720,851    decoded 10,142,807
6 fonts                 2.72 MB of TTF on disk; flash cost is the
                        generated glyphs, not the TTF
text cache              192 KB default, VRAM
Shapes buffers          ~83 KB VRAM
layer buffers           OTF, 1280 × line_height × 4
```

Earlier in the same session it was 777,143 and 13,389,182. The 3.25 MB came
off from two changes, neither of which touched a pixel:

- deleting a dead function that kept eleven images alive
- cropping eleven route layers to the box they actually occupied

## Where to look first

In order of how much they usually return:

1. **Stay on OTF.** 4.9 MB versus 330 KB is not a close call.
2. **Alpha8 everything that can be.** 4× on the decoded total.
3. **Trim transparent borders.** Lossless, and often 90%+ on overlay art.
4. **Find dead art reachable only from dead code.** Free.
5. **One PNG per size** — quality and cost in the same change.
6. **Cut the text cache** from its 192 KB default.
7. **Bpp24 instead of Bpp32** on the bottom layer — 25% of the layer buffer.
8. **Count your font configurations** (chapter 9).

Not on the list, because measurement said no: deleting unreferenced files
(already absent from the binary), and halving mirror-symmetric layers (four
files qualified, not forty).

## Check it yourself

```
size build/<config>/<target>
```

```
find build -name "*.S" | xargs ls -lS | head        # resource and glyph blobs
```

Decoded image total: the script in chapter 6.

And the honest one — put a counter on your largest screen's `prepareFrame` and
watch the high-water mark while you navigate every page. Peak is what has to
fit, not average.

## Sources

- [Layer and VRAM optimization for TRAVEO T2G](https://doc.qt.io/QtForMCUs/qtul-t2g-layer-vram-guide.html)
- [Qul::ApplicationConfiguration](https://doc.qt.io/QtForMCUs/qul-applicationconfiguration.html)
- [Managing resources](https://doc.qt.io/QtForMCUs/qtul-resources.html)
