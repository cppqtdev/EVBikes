# 06 — Images and resources

Images are usually the biggest thing you control. This chapter is the one with
the most measured numbers in it, because image cost is easy to measure and
easy to get wrong by a factor of four.

## Two costs, not one

Every image has **two** sizes and they move independently:

- **Flash** — the compressed bytes stored in the binary or in external flash
- **Decoded** — `width × height × bytes_per_pixel`, the space it occupies once
  it is usable

Compression shrinks the first and does **nothing** to the second. A 16 KB PNG
that is 1154×480 decodes to 553,920 bytes. This is the number people miss.

Measured on this cluster at one point:

```
252 images referenced by QML
  flash      777,143  (759 KB)
  decoded 13,389,182  (12.77 MB)
```

Seventeen times larger decoded than stored. Budget the second number.

## Bytes per pixel is the main lever

| Format | Bytes/px | For |
|---|---|---|
| Alpha8 (alpha map) | **1** | Monochrome art tinted at runtime |
| RGB565 | 2 | Opaque colour, no alpha |
| RGB888 | 3 | Opaque colour, full precision |
| ARGB8888 | 4 | Colour with alpha |

Alpha8 is four times cheaper than full colour, and for an HMI it covers almost
everything: icons, glows, frames, outlines, cards. The trick is to draw the art
as a **white mask** and colour it at runtime:

```qml
ColorizedImage {
    source: "qrc:/assets/icons/32/tt_abs.png"   // pure white artwork
    color: Theme.amber                           // tinted here
}
```

Same file, any colour, one byte a pixel. In this project 247 of 252 images are
Alpha8; the five that are not are photographs.

### Decide it by measuring, not by naming

An image qualifies as Alpha8 only if **every visible pixel is pure white**.
Deciding that from a file name is how you silently ship a 4× image:

```python
def alpha_only(path):
    """Open it and check. Names lie."""
    im = Image.open(path).convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            if a and (r, g, b) != (255, 255, 255):
                return False
    return True
```

This project got that wrong first by matching names, and the fix was to look at
the pixels.

## One PNG per size

> **An image is drawn at its own size.** Showing a 40 px file at 24 px means
> resampling by a fraction, every frame, and the thin strokes disappear.

This is the single most visible quality bug in an MCU HMI, and it is easy to
create: one icon used in three places at three sizes.

In this cluster every telltale drew at one size while the files were 24, 28,
32, 34, 36 and 40. All of them were being resampled by a fraction. They looked,
in the words of the person who had to look at them, cheap and broken.

The fix is a vector master and a build step:

```
assets/icons/src/tt_abs.32.svg   →   assets/icons/32/tt_abs.png
assets/icons/src/wrench.24.32.svg →  assets/icons/24/wrench.png
                                     assets/icons/32/wrench.png
```

The sizes live in the file name, so adding one is a rename. `tools/build_icons.py`
rasterises with Pillow only — no native dependency, so it runs anywhere — and
writes pure white with the shape in the alpha channel, which keeps the Alpha8
path. It also warns when a source is smaller than the size asked for, instead
of quietly enlarging it.

### Drawing icons that survive at 24–32 px

Hard-won, from redrawing twenty-three of them:

- **Gaps must exceed the stroke width.** Letters 1.1 units apart with a 1.1
  stroke merge into a blob. At 1.5 they read. This was the whole reason an
  "ABS" mark was unreadable.
- **Solid beats outline at small sizes.** A filled engine-block silhouette
  reads where a thin outline turns to mush.
- **Keep a 3–8 px inset.** Art running edge to edge looks cramped next to art
  that does not.
- **Check the aspect ratio is the symbol's own.** One icon here was a circle
  drawn as a 72×56 ellipse. A battery being wider than tall is correct; a
  circle being wider than tall is a bug. One measurement found it:

```python
bb = im.split()[3].getbbox()
print((bb[2]-bb[0]) / (bb[3]-bb[1]))   # 1.29 for a "circle"
```

## Trim the transparent border

A large image that is mostly empty costs its full rectangle, decoded. Trimming
to the alpha bounding box and moving the draw position by the same amount is
**lossless** — not a pixel changes.

Measured here:

| | before | after |
|---|---|---|
| `route_destination.png` | 660×270 | 20×138 — 98% was empty |
| `hexroute_destination.png` | 495×305 | 12×85 — 99% was empty |

Forty files, **5.57 MB → 1.12 MB decoded**.

### The catch with a shared Image element

If eleven variants go through **one** `Image` whose `source` changes, they
cannot each have their own trim — they must share a size and an origin. Crop
them all to one box that holds all of them, and have the generator fail the
build if a variant ever outgrows it:

```python
HEX_ROUTE_CROP = (180, 94, 407, 244)
if ink and not inside(ink, HEX_ROUTE_CROP):
    raise ValueError(f"{f}: ink {ink} outside the crop box; widen it and move "
                     "the QML x and y by the same amount")
```

That assertion is the part that keeps the art and the QML in step a year later.

## Cache policy

| `MCU.resourceCachePolicy` | Behaviour |
|---|---|
| `NoCaching` | Stay in flash, read in place |
| `OnStartup` | Decoded into RAM at boot |
| `OnDemand` | Decoded when first used |

On a board reading from external flash with no cache, compression is pointless
— you pay to decompress and gain nothing:

```qml
MCU.resourceCompression: false
MCU.resourceCachePolicy: "NoCaching"
MCU.resourceStorageSection: "QulResourceDataInExternalFlash"
```

On desktop the opposite. Keep these in separate build profiles (chapter 2).

`maxResourceCacheSize` caps the cache. Set it from your measured decoded total
plus headroom, not from a round number.

## Dead art hides inside live code

The sweep everyone runs is "which files does the QML name". It is not enough.

`Format.routeImage()` in this project had **no caller** — the classic map draws
its route with `Shapes`. But the eleven paths were string literals *inside that
function*, and the resource list is built from the paths the QML names. All
eleven were compiled in: 52 KB of flash and 1.96 MB of cache for pictures
nothing ever drew.

> **Ask "which paths are reachable", not "which paths appear".** Delete the
> dead function and the images leave with it.

## What *not* to bother with

Two things measured here that looked promising and were not:

**Mirroring symmetric layers.** Store half, draw twice flipped. A loose test
(mean difference) said 40 of 48 layers were symmetric — a 4.8 MB saving. A
strict test (max difference, and count the differing pixels) said **four**,
worth 570 KB. `glow_alert` had 53,530 differing pixels. Halving it would have
been visible. The loose test was the bug.

**Deleting unreferenced files.** Saves nothing. Flash is built from the paths
the QML names, so a file nobody references is already absent from the binary.

## Check it yourself

Flash and decoded totals:

```python
import re, glob, os
from PIL import Image
used = set()
for q in glob.glob("qml/**/*.qml", recursive=True):
    used |= set(re.findall(r'"qrc:/(assets/[^"]+\.png)"', open(q).read()))
flash = dec = 0
for p in sorted(used):
    w, h = Image.open(p).size
    flash += os.path.getsize(p)
    dec   += w * h * (1 if alpha_only(p) else 4)
print(f"{len(used)} images  flash {flash:,}  decoded {dec:,}")
```

Who is wasting the most on transparent border:

```python
bb = Image.open(p).convert("RGBA").split()[3].getbbox()
waste = 1 - ((bb[2]-bb[0]) * (bb[3]-bb[1])) / (w * h)
```

## Sources

- [Managing resources](https://doc.qt.io/QtForMCUs/qtul-resources.html)
