# 09 — Fonts and text

Fonts are the quietest flash consumer. Nobody notices them growing, because
each individual addition is small and invisible, and the total only shows up in
a map file nobody reads.

## Two engines, pick one knowingly

| | **Static** | **Monotype Spark** |
|---|---|---|
| When glyphs are rasterised | Build time, with FreeType | Runtime |
| Flash | Precomputed glyph bitmaps | The font plus the engine |
| RAM | None for rasterising | `fontHeapSize` + `fontCacheSize` |
| Font configuration | Must be **constant** | May vary at runtime |
| Arbitrary runtime strings | Only if pre-registered | Yes |
| Scaling text smoothly | No | Yes |

```qml
MCU.Config {
    fontEngine: "Static"
    defaultFontFamily: "Inter"
    addDefaultFonts: false
    autoGenerateGlyphs: true
    Experimental.mergeStaticTextGlyphs: true
}
```

Most clusters want Static. You know your strings, you do not scale text, and
you would rather spend flash than RAM.

## What the static engine demands

> The static engine supports **constant font configurations only**. `family`,
> `weight`, `italic` and `pixelSize` must be known at compile time.

Which produces the rules from chapter 3:

```qml
font.pixelSize: someProperty          // no
font.pixelSize: 22                    // yes
font: active ? Theme.big : Theme.small // yes, if both are readonly Qt.font({...})
someFont.pixelSize                    // no — a font cannot be read back
font.weight: Font.DemiBold            // no — Spark only
```

## Which glyphs get compiled in

With `autoGenerateGlyphs: true` (the default), the compiler includes:

- a small common set — digits and similar
- **every character appearing in a QML string literal**, for **every font
  configuration**

With it off, only what `font.unicodeCoverage` declares.

That phrase — *for every font configuration* — is the whole cost model.

## The configuration explosion

A configuration is a distinct `(family, pixelSize, weight, italic)`. **Each one
gets its own rasterised glyph set in flash.**

Counted in this project:

```
45 distinct (size, weight, style) combinations
   sizes: 9 10 11 12 13 14 15 16 17 18 19 20 21 22 24 26 28 30 32 34 52 54 57 64 124
   plus bold and italic variants of many
```

Forty-five. Nobody decided that; it accumulated one `font.pixelSize: 17` at a
time.

The cost is not even across them. A glyph at `pixelSize: 124` is roughly
74×93 pixels — about 6.9 KB each at one byte a pixel. Ten digits at that size
is **~69 KB from one configuration**. The sizes 124, 64, 57, 54 and 52 are
likely to dominate everything else combined.

### What to do

- **Consolidate neighbours.** 13/14/15 → one. 16/17/18 → one. 19/20 → one.
  22/24 → one. 26/28/30 → one. Forty-five becomes about twenty, and nobody
  will see the difference.
- **Put sizes in a theme, not in pages.** `Theme.bodyFont`, `Theme.labelFont`.
  A page that cannot name a pixel size cannot invent a forty-sixth.
- **Audit the big ones.** For a size used once, for digits only, consider
  `font.unicodeCoverage` restricted to `0-9` instead of the auto set.
- **Drop unreachable faces.** This project ships six Inter TTFs, but
  `font.weight` is banned by its own lint — so only Regular and Bold × Italic
  are reachable. `Inter-SemiBold` and `Inter-SemiBoldItalic`, 944 KB of TTF,
  are being handed to the font compiler for nothing.

## `StaticText` and merging

`StaticText` combines an item's glyphs into a **single image** at build time —
no runtime shaping. With `Experimental.mergeStaticTextGlyphs: true` it is the
cheapest way to put fixed text on screen.

Limitations: always left aligned, no Spark, no rich text.

Use it for labels — `RANGE`, `ODO`, `KPH`, menu titles. Use `Text` for values
that change.

## Drawing numbers without `String.length`

Live numeric readouts are most of a cluster, and the JavaScript subset has no
`String.length`. Two patterns that work.

**Digit by digit, fixed cells.** Each digit in its own cell so the row does not
shift sideways as the value counts:

```qml
Repeater {
    model: readout.cells                 // constant, see chapter 3
    Text {
        x: (index - readout.blanks) * readout.cellWidth
        text: index < readout.blanks ? ""
              : Format.digitAt(readout.shownValue, readout.cells - 1 - index)
        font: readout.digitFont
    }
}
```

```qml
function digitAt(value: int, position: int) : string {
    var v = Math.floor(value)
    for (var i = 0; i < position; i++)
        v = Math.floor(v / 10)
    return "" + (v % 10)
}
```

**Counting digits by arithmetic**, since `String.length` is gone:

```qml
readonly property int used: {
    var rest = Math.abs(shownValue)
    var count = 1
    while (rest >= 10) { rest = Math.floor(rest / 10); count = count + 1 }
    return count
}
```

Number to string is `"" + value`. Keep it that simple.

## Text alignment, exactly

A `Text` with a `height` and no `verticalAlignment` sits at the **top** of its
box. If you are lining text up against something else, that is a couple of
pixels of drift that looks like carelessness:

```qml
Text {
    y: 92; height: 24
    verticalAlignment: Text.AlignVCenter    // now its centre is the box centre
}
```

Worth setting whenever text shares a row with an icon or a control.

## The text cache

192 KB of VRAM by default — see chapter 7. With the static engine the glyphs
are in flash, so the cache holds only the text that changes, and cutting it is
usually safe:

```cpp
#include <qul/application.h>
Qul::ApplicationConfiguration config;
config.setTextCacheSize(96 * 1024);
Qul::Application app(config);
```

## Check it yourself

Count your configurations:

```python
import re, glob, collections
cfg = collections.Counter()
for q in glob.glob("qml/**/*.qml", recursive=True):
    s = open(q).read()
    for m in re.finditer(r'Qt\.font\(\{([^}]*)\}\)', s):
        b = m.group(1)
        size = re.search(r'pixelSize:\s*(\d+)', b)
        cfg[(size.group(1) if size else "?",
             'bold' in b, 'italic' in b)] += 1
    for m in re.finditer(r'font\.pixelSize:\s*(\d+)', s):
        cfg[(m.group(1), False, False)] += 1
print(len(cfg), "configurations")
```

Which faces are actually reachable:

```
grep -rn "font.weight" qml/      # nothing? then only Regular/Bold x Italic
```

And on the board, what the glyphs actually cost:

```
find build -name "*Font*" -o -name "*.S" | xargs ls -lS | head
```

## Sources

- [Text rendering and fonts](https://doc.qt.io/QtForMCUs/qtul-fonts.html)
- [MCU.Config.autoGenerateGlyphs](https://doc.qt.io/QtForMCUs/qtul-qmlproject-mcu-confignode-autogenerateglyphs.html)
- [StaticText](https://doc.qt.io/QtForMCUs/qml-qtquickultralite-extras-statictext.html)
