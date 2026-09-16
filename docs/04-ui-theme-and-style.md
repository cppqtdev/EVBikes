# 04 · UI theme, colours, fonts, gradients and effects

All values live in `qml/core/Theme.qml`. Screen: **1280 × 480**. Layout positions follow the reference frames (see `15-ui-design-implementation.md`).

## Colour palette

| Token | Hex | Use |
|---|---|---|
| `black` | `#000000` | Screen background (saves power on OLED, best contrast) |
| `white` | `#FEFEFE` | Main numbers and text |
| `teal` | `#6FFFD8` | Accent in Eco / Normal mode, glow, selected items |
| `orange` | `#DE5013` | Accent in Sport mode, battery bar |
| `tealDeep` / `orangeDeep` | `#1C8C74` / `#8A2A08` | Start colour of gradients, lower bar segments |
| `tealDim` / `orangeDim` | `#123F36` / `#3A1A0E` | Chip and card backgrounds |
| `red` | `#FF3B30` | Critical alerts, red telltales |
| `amber` | `#FFB020` | Warnings, amber telltales |
| `green` | `#3DDC84` | Indicator telltales, call answer |
| `blue` / `telltaleBlue` | `#4FC3F7` / `#3D8BFF` | Bluetooth, regen, high beam |
| `surface` / `surfaceRaised` | `#12181D` / `#1A2228` | Cards |
| `textSecondary` / `textMuted` | `#A3AEB6` / `#5B666E` | Labels, disabled |

### Mode-driven accent

```
accent = critical alert ? red : (Sport ? orange : teal)
```

- The whole frame glow, bars, chip and highlights change colour with one binding.
- Colour change is animated (`ColorAnimation`, 420 ms) so it never "flashes".

### Telltale colours (follow ISO 2575 meaning)

- **Red** = danger, stop (side stand while moving, critical battery, critical fault)
- **Amber** = warning, check soon (ABS fault, low battery)
- **Green** = system on (indicators, low beam)
- **Blue** = high beam

## Typography

- Font: **Inter** (Regular, SemiBold, Bold, Bold Italic) — `assets/fonts`, OFL licence file included.
- Static font engine: only the glyphs used in the app are stored in flash (`autoGenerateGlyphs: true`).

| Token | Size | Use |
|---|---|---|
| `fontSpeed` | 132 px bold italic | Speed |
| `fontDisplay` | 44 px | Turn distance, PIN digits, tyre psi |
| `fontTitle` | 28 px | Range / ODO values, alert title |
| `fontHeading` | 22 px | Clock, mode chip, card values |
| `fontBody` | 18 px | Instructions, menu rows |
| `fontLabel` | 14 px | Labels (RANGE, ODO, KPH) |
| `fontCaption` | 12 px | Bar labels (MAX, AMP, RPM) |

- Minimum size while riding: **14 px** (about 3 mm on a 7-inch screen). Speed digits ≥ 100 px.
- Italic for "moving" numbers (speed, range) gives the sporty look from the design.

## Gradients, shine and glow (Ultralite-friendly)

Qt Quick Ultralite has **no shaders, no blur, no drop shadow**. We get the same look like this:

| Effect | How | Cost |
|---|---|---|
| Frame neon glow | Pre-blurred white PNG (`frame_glow.png`) tinted with `ColorizedImage` | 1 image blend |
| Soft light behind speed / alerts | `glow_blob.png` (radial alpha) tinted + opacity | 1 image blend |
| Metallic speed digits | Same text twice: grey full + white top half inside a clipped `Item` | 2 text draws |
| Card and chip depth | `Rectangle.gradient` (vertical) | cheap |
| Battery / temp bars | `Rectangle.gradient` with `orientation: Gradient.Horizontal` | cheap |
| Segmented AMP/RPM bars | `segment.png` parallelogram tinted per segment, opacity ramp | N image blends |
| 3D road on nav page | Static perspective grid `road_grid.png` tinted | 1 image blend |

- All white artwork is stored as **Alpha8** (1 byte per pixel) → 4× less flash than ARGB.
- Re-create or tweak images with `python3 tools/generate_assets.py`. Replace with designer exports at the same size when ready (keep them **white on transparent**).

## Spacing, radius, motion

- Spacing: 4 / 8 / 12 / 16 / 24 px. Radius: 4 / 8 / 14 px.
- Motion: 120 ms (focus), 220 ms (page fade), 420 ms (colour, bars).
- Only animate **opacity, position, width, colour**. No scaling or rotating big items (costly on MCUs).

## Day / night

- `SystemData.nightMode` dims text colours. Wire the light sensor to it on the board.
- Backlight: `SystemData.setBrightnessLevel()` → `platform::setBacklight()`.
- Must be readable in **direct sun**: high contrast white on black, big numbers, no thin fonts.
