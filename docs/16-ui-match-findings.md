# Matching the cluster to the reference frames

There is no Figma for this project. The reference is the frames pulled out of
the design video: `all_frames/` (1355 frames), plus the earlier `screens/`,
`screen2/` and `screens3/` sets. Comparing a 1280 x 480 cluster against a
1920 x 1080 frame by eye is how padding drifts four pixels everywhere and
nobody can say by how much, so this is measured instead.

## The mapping

A frame is 1920 x 1080. The cluster is drawn in it at

    frame_x = cluster_x * 1.5
    frame_y = cluster_y * 1.5 + 187.5

The horizontal half of that is exact: the teal ink in a clean ride frame runs
x 138 .. 1782, centred on 960.0, which is 92 .. 1188 in cluster pixels,
centred on 640. The vertical offset is the calibration
`tools/generate_cluster_art.py` was drawn from, and the housing top edge
lands where it predicts to within two rows, so the art is not systematically
high or low.

## The tools

- `tools/uicompare/refcluster.py frame.png out.png` crops a reference frame to
  the cluster rectangle and scales it to 1280 x 480, so a reference and a
  screenshot can be compared pixel for pixel with no arithmetic in between.
- `tools/uicompare/measure.py shot.png reference.png` prints the difference in
  numbers: ink box, bright bands across and down, colour probes.
- `tools/color_check.py` fails the build on the colour-cast fault below.

`frame_0542.png` is the cleanest ECO ride frame and is the reference used for
every number here.

## Reference numbers, in cluster coordinates

| element | x | y | size |
|---|---|---|---|
| AMP bar teal, left limb | 92 .. 399 | 51 .. 455 | - |
| RPM bar teal, right limb | 880 .. 1188 | 53 .. 456 | - |
| speed digits "57" | 228 .. 414 | 136 .. 242 | 187 x 107 |
| trip digits, four cells | 940 .. 1063 | 162 .. 193 | pitch 38.3 |
| battery bar track | 398 .. 592 | 382 .. 395 | 194 x 14 |
| temperature bar track | 684 .. 878 | 382 .. 395 | 194 x 14 |

The two bar limbs are symmetric: the left starts 92 in from the left edge, the
right ends 92 in from the right. Any difference between those two numbers in
our build is a bug on its own.

## Reference colours

Everything dark in the reference is a **neutral** grey.

| point | reference | ours, before |
|---|---|---|
| top strip plate | `#0F0F0F` | `#14181A` |
| housing, mid panel | `#08090B` | `#0B0E0F` |
| ride-mode chip | `#222222` | `#1D2224` |
| bar track, empty | `#383737` | `#3E4345` |
| speed digit body | `#D9D9D9` | `#F1F3F3` |
| speed digit tail | `#ADD5CB` | `#A6E3D2` |
| KPH | `#C4D5D2` | `#B6F2E0` |
| RANGE / ODO labels | `#8FB4AB` | `#9DE0CE` |
| bar segment, bottom | `#274337` | `#3A8874` |
| bar segment, top | `#CDCDCD` | `#D3D8D6` |
| battery fill, start .. end | `#904229` .. `#969683` | flat `#A9492B` |
| temperature fill, cool | `#91C0A9` | `#9FD8C0` |
| temperature fill, hot end | `#8F432B` | never drawn |

## The faults, and what was done

### 1. Every dark surface leaned teal

Forty-three colour literals across the QML were near-greys with green and
blue a few steps above red - `#1E2123`, `#15191B`, `#1C2123`, `#4A4F52` and so
on - and the theme tokens did the same. Alone each is invisible; together they
are why the whole cluster reads green against the reference.

Fixed: the tokens in `Theme.qml` and 23 distinct literals were replaced with
the neutral grey of the same perceived luminance. `tools/color_check.py`
fails on any dark literal whose channels spread 4 to 10 steps, which is the
drift without catching the deliberate greens.

### 2. The speed reading was three stacked copies of the text

`SpeedDigits.qml` drew the number three times to fake a gradient: white
`#F1F3F3` for the top 72 rows, `#D6D9DA` for the middle, mint for the bottom
60. The result is two hard horizontal cuts straight across the digits.

The reference is flat `#D9D9D9` for the whole glyph and fades to `#ADD5CB`
over its last 18 rows only, with no bright top band at all.

Fixed: one body text, a six-band fade over the measured 18 rows, one flat
tail. The size was never wrong - ours measured 188 x 110 against the
reference's 187 x 107 - so `fontSpeed` stays at 150; the glyph was 4 px left
and 2 px high, which is now corrected in `RideView.qml`.

### 3. Horizontal gradients do not render

`BatteryTempBars.qml` drew both bottom bars with
`Rectangle { gradient: Gradient { orientation: Gradient.Horizontal ... } }`.
Neither gradient appears in the build: the battery fill is flat brick with a
hard cut at the fill edge, and the temperature bar never shows the warm end
the reference has.

Fixed: both ramps are now clipped bands over the pointed-bar art, the same
idiom the generated bars already use. The battery fill runs `#904229` to
`#969683` across the fill; the temperature bar keeps `#91C0A9` and turns to
`#8F432B` across a fixed warm zone at the top of the scale, matching the
reference, and the ruler ticks were lifted from 0.35 to 0.6 opacity so they
are visible at all.

### 4. The two bars used different ramps

`ClusterShell.qml` overrode `RpmBar.lowColor` and `highColor` with `#2C8C72`
and `#5CEFC4`, so the right bar was duller than the left. The reference draws
both the same. Override removed; both take `Theme.segLow` / `segHigh`.

### 5. Colours bypassed the theme

`BottomDock.qml` filled with `"#20262A"` and `TripCounter.qml` with
`"#DDEFEA"` and `"#121617"`. These are now `Theme.surface`,
`Theme.labelTeal` and `Theme.surfaceSunken`.

## The screenshot is older than the build

`Claude outputs/ride-layout-vs-reference.png` was captured at 12:22 and the
art was regenerated at 14:28. Several glyph differences read off it are
already gone: the assets on disk now draw the beam-and-D headlight, the
doubled chevrons, the battery body around the bolt and the outline
thermometer with its degree circle, all of which match the reference.
`python3 tools/generate_assets.py` rewrites nothing, so the art and the
generator agree.

Everything fixed above was read out of the source, not the screenshot, so
none of it depends on that picture. Everything left below was read off the
screenshot and wants a fresh one before anyone acts on it.

## Close-up findings on the hexagon screen (frame_1318)

### The gauge backdrop is translucent, ours was opaque

The dark plate behind the hexagon lets the terrain wireframe read through it.
Measured on the same grid: contrast under the plate is 34.0, outside it 71.7,
so the plate passes about 47 per cent of what is behind. Ours painted it as a
solid fill and hid the terrain completely. It carries `opacity: 0.5` now.

### The selected settings control is a well, not a raised plate

Cross-section at x 860 in the reference:

| rows | reading |
|---|---|
| 405 .. 413 | the two teal dock strokes |
| 414 .. 445 | falls from `#171E1D` to `#020202` |
| 446 .. 457 | lifts back to `#3B3937` |
| 458 on | the dock plate, `#12100E` |

So it is a recessed black well with a lit bottom lip and a light wedge down
its left diagonal. Its left edge runs (770, 414) to (818, 456) - it leans
**right** going down.

Ours drew `band_right.png` as a flat `#202020` plate and its slant leaned the
other way. The art is rebuilt with the measured slant, plus a
`band_right_lip.png` carrying the edge light; the well is `#020202` and the
lip `#3A3A3A`.

The reference shows this selected state on the hexagon screen and not on the
classic ride screen. Ours ties it to `menuActive`, which the hexagon view
never sets, so it never appears there. That is a behaviour question, not a
measurement, and is left alone.

### Dock spacing was already right

Ink columns in the reference, y 415..462: D at 429..448, compass 514..546,
ECO 611..661, bell 742..762, gear 836..855. Ours places them at 427, 512,
610..661, 740..764, 832..856. Nothing to change.

## Still open

- **The bike render.** Ours looked like a different motorcycle from the
  reference's - a heavier, more upright silhouette against a slim faired
  sportbike - and 13 px wider, 6 px left. New art if it still does.
- **The compass glyph** in the dock is a diamond in an ellipse; the reference
  is a north arrow.
- **Soft shadows.** The reference puts a soft glow behind the speed digits and
  a vertical lift across the housing interior. Ours is flat. Both want
  pre-rendered art rather than a runtime blur.
- **The bar knee.** `BAR_KNEE_RADIUS` is 30 but the rendered bend looked
  square against the reference's rounded one.
- **The ride-mode chip** under ECO read harder-edged and lighter than the
  reference's, which is nearly invisible against the dock.

## Behaviour round

Not everything wrong with a screen is a measurement. These came out of the same
pass and are fixed in the source rather than in the art.

- **Numbers flickered** because a `Text` bound to a value re-lays out on every
  change and proportional digits are different widths, so whatever followed the
  number moved with it. `NumberReadout` gives each digit a fixed cell and
  animates the displayed value; `fit` mode keeps a row flowing so it only moves
  when a digit is gained or lost.
- **The turn indicators never blinked.** They run at 1.2 Hz now, and every
  telltale crossfades its colour instead of cutting.
- **The route was a picture.** `MapView` chose one of nine PNGs from the
  maneuver, so nothing moved during a trip. It is a cubic driven by the
  maneuver and the distance to it, with the bend pulling down towards the rider
  as the turn arrives.
- **`TabStrip` hard-coded 96 px a cell**, so `Shortcut keys` was wider than its
  own pill. Cells size to their labels.
- **The charging ring** swept its whole progress in one arc with `useLargeArc`,
  which is where it rendered ragged past halfway. Two half-sweeps, and a
  smaller radius.
- **`MenuCarousel`** re-labelled three fixed tiles. It is a `PathView`, so the
  titles slide and the direction of travel is visible.
- **A call** arrived as a corner banner. `CallScreen` takes the display.
- **`make_avatar` and `make_album_art`** drew at fixed pixel sizes while only
  the canvas changed, so the smaller copy was a different picture. Both scale
  their coordinates now - the same bug, twice, worth checking for in any other
  generator that takes a size.

## Re-measuring after a change

    python3 tools/uicompare/refcluster.py all_frames/frame_0542.png .cmp/ref.png
    python3 tools/uicompare/measure.py shot.png .cmp/ref.png

A screenshot of the ride screen at exactly 1280 x 480 is all that is needed.
