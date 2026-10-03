# 08 — Layers and bits per pixel

Layers are how you trade VRAM against flexibility. The guidance below is from
Qt's TRAVEO T2G guide; the numbers are worked for a 1280×480 screen, and the
two "don't" sections are measured on real artwork.

## The three layer types

| Type | What it is | Use for |
|---|---|---|
| **`ItemLayer`** | A renderable container of dynamic content. OTF by default, or buffered via rendering hints | Anything that changes |
| **`ImageLayer`** | Reads pixels straight from addressable flash | Static backgrounds and foregrounds |
| **`SpriteLayer`** | A compositing layer; its depth must match the depths of the layers inside it | Composing the above |

```qml
import QtQuickUltralite.Layers

ItemLayer {
    depth: ItemLayer.Bpp24
    width: 1280; height: 480
    ClusterShell { }
}
```

## Rendering modes, and why one of them matters far more

### On-the-fly (OTF) — the default

No framebuffers. The engine records a command buffer and replays it at display
refresh through a circular **line buffer** (32, 64, 128 … pixels tall).

```
WIDTH × LINE_BUFFER_HEIGHT × BPP  +  COMMAND_BUFFER_SIZE
```

Qt's own example: 800×480 at 24 bpp with a 64-line buffer ≈ **219 KB**.

### IBO — double buffered

`ItemLayer.renderingHints: ItemLayer.NoRenderingHint`.

```
WIDTH × HEIGHT × 2 × BPP
```

### LBO to memory

`ItemLayer.OptimizeForSpeed`. Same memory as IBO; buffers commands line by line.

### The number that decides everything

For 1280×480:

| Mode | at 32 bpp |
|---|---|
| OTF, 64-line buffer | **327,680** |
| Double buffered | **4,915,200** |

Fifteen times. **Every other optimisation in this guide is smaller than the
difference between these two rows.** Decide this first, and stay on OTF unless
something forces you off it.

One caveat worth knowing: in OTF mode, content that has not changed is still
redrawn at display refresh. Putting slow-changing content in a buffered layer
saves drawing work — and costs VRAM. That is a real trade, not a free win.

## Colour depth

| Depth | Bytes | Saving vs Bpp32 |
|---|---|---|
| `Bpp32` (default) | 4 | — |
| `Bpp24` | 3 | **25%** |
| `Bpp16`, `Bpp16Alpha` | 2 | 50% |

Qt's guidance: prefer **`Bpp24`** for the bottom-most `ItemLayer`. It has no
alpha, which an opaque bottom layer does not need, and it keeps full colour
precision.

Worked for 1280 wide:

| line buffer | 32 bpp | 24 bpp | saved |
|---|---|---|---|
| 32 | 163,840 | 122,880 | **40,960** |
| 64 | 327,680 | 245,760 | **81,920** |
| 128 | 655,360 | 491,520 | **163,840** |

Read your line-buffer height from `platform_config.h.in`.

## Don't: 16 bpp on a dark UI

RGB565 keeps 5 bits of red, 6 of green, 5 of blue. On a bright interface that
is often acceptable. On a dark automotive HMI it is not, and here is the
measurement rather than the opinion.

Background `#060809` — a neutral near-black:

```
r = 6 >> 3 = 0  →  0
g = 8 >> 2 = 2  →  8
b = 9 >> 3 = 1  →  8
```

`(6, 8, 9)` becomes `(0, 8, 8)`. Neutral black becomes **green-tinted black,
across the entire screen**.

And in a tinted glow region, distinct colours dropped from **155 to 61** — more
than half the gradient steps gone, which is visible banding on exactly the
soft glows this kind of design is built from.

Max channel error was only 7, which is why a casual look says "fine". The
defect is not the magnitude, it is that it applies to every dark pixel at once
and shifts the hue.

> Check your own background before trusting either answer. Four lines:
> ```python
> r,g,b = 6,8,9
> print((r>>3)<<3, (g>>2)<<2, (b>>3)<<3)
> ```

## Don't: a layer per widget

The tempting idea: header at 16 bpp, background at 24, glows at 32, each its
own layer.

Qt's guide is explicit that **every layer brings its own buffers and command
buffer**, so a layer placed over a full-screen one can cost more than it saves.

And on a typical cluster there is nothing to split along. In this one the
chrome is `shell_backing`, `shell_edge`, `glow_ride` and `panel_haze` — all
roughly 1120×460 and all **overlapping**. There is no rectangle that is "only
the header", because the housing art runs behind it.

> Prefer a few carefully sized layers over many small ones, and compare the
> combined VRAM budget before and after rather than assuming the split helps.

## The other VRAM knobs in the same guide

| Setting | Default | Note |
|---|---|---|
| `MCU.Config { resourceCachePolicy: "NoCaching" }` | caching on | Qt's first recommendation. `OnStartup` only for rotated or scaled images |
| `MCU.Config { glyphsCachePolicy: "NoCaching" }` | caching on | Qt's second |
| `fontHeapSize` | — | **Monotype Spark only.** 24–64 KB |
| `fontCacheSize` | 200 KB | **Spark only.** ~32 KB suggested |
| text cache | 192 KB | `ApplicationConfiguration::setTextCacheSize()` |
| global alpha buffer | 320×320 @ 4bpp ≈ 51 KB | Shapes; set in `platform_config.h.in` |
| global path buffer | 32 KB | Shapes |

If you use the **static** font engine, the two Spark rows do not apply to you.
Check which one you are on before budgeting for either.

Insufficient VRAM for a per-path mask shows up as
`QulError_DrawingEngine_SurfaceAllocationFailed` — a real error, not a silent
degradation.

## A validation routine

1. **Which mode am I in?** OTF or buffered. Everything else is noise until
   this is answered.
2. **Compute the layer buffer** from the formula and your line-buffer height.
   Write the number down.
3. **Add the four VRAM consumers** from chapter 7: layers, image cache, text
   cache, vector buffers.
4. **Compare against the platform budget.** Not a round number — the actual
   figure from your board's memory map.
5. **Change one thing, recompute, and look at the screen.** Dark gradients and
   the smallest text are where depth reductions show first.
6. **Watch for `SurfaceAllocationFailed`** while navigating every screen, not
   just the first.

## A note on doing this honestly

The 24 bpp root layer is, on paper, the largest single VRAM saving available
to this project — 41 to 160 KB. It is not implemented, for reasons worth
stating because they will apply to you too:

- the QML is shared with two desktop builds, and plain Qt 6 has no `ItemLayer`,
  so it needs a shim the way `ColorizedImage` has one
- there is no board on hand to verify it

Breaking two working builds for a saving that cannot be measured is the wrong
trade on that day. Write the specification down, implement it when the board
is in front of you, and verify it the same hour. A number you cannot check is
not a saving, it is a hope.

## Check it yourself

```
grep -rn "LINE_BUFFER_HEIGHT\|lineBufferHeight" $QUL_DIR/platform/boards/<board>/
```

```
grep -rn "ItemLayer\|ImageLayer\|SpriteLayer" qml/
```

Nothing found by the second means everything is on the one default layer, at
the platform's default depth.

## Sources

- [Layer and VRAM optimization guide for Infineon TRAVEO T2G](https://doc.qt.io/QtForMCUs/qtul-t2g-layer-vram-guide.html)
- [Qt Quick Ultralite QML types](https://doc.qt.io/QtForMCUs/qtul-qmltypes.html)
