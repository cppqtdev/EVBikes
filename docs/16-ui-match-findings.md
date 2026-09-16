# Matching the cluster to the reference frames

There is no Figma for this project. The reference is the frames pulled out
of the design video, in `screens/` and `screen2/`. Comparing a 1280 x 480
cluster against a frame by eye is how padding drifts four pixels everywhere
and nobody can say by how much, so this is measured instead.

## The mapping

`screens/frame_NNN.png` is 1920 x 1080. The cluster is drawn in it at

    frame_x = cluster_x * 1.5
    frame_y = cluster_y * 1.5 + 195

Checked on `frame_022`: the cluster is exactly 1.5 times its 1280 px width,
and the top of the housing lands 195 px down the frame.

## The tool

`tools/uicompare/measure.py` reads a screenshot and a reference frame and
prints the difference in numbers: the ink box, where the bright things start
and stop across and down the screen, and the colour at a set of probes.

    tools/uicompare/measure.py shot.png screens/frame_022.png
    tools/uicompare/measure.py --split stacked.png

Everything below came out of it.

## Reference numbers, in cluster coordinates

Measured from `screens/frame_022.png`, the cleanest ECO ride frame:

| element | x | y | size |
|---|---|---|---|
| left battery column, teal | 91 .. 286 | 46 .. 423 | 196 x 378 |
| right battery column, teal | 993 .. 1187 | 47 .. 424 | 195 x 378 |
| speed digits "57" | 229 .. 435 | 130 .. 223 | 207 x 94 |
| top strip, whole row | 349 .. 946 | 4 .. 63 | 598 x 60 |
| dock ECO chip, teal | 610 .. 661 | 422 .. 440 | 52 x 19 |

The two battery columns are symmetric: the left starts 91 in from the left
edge, the right ends 93 in from the right. Any difference between those two
numbers in our build is a bug on its own.

Colour probes on the same frame:

| point | reference |
|---|---|
| dock background | `#262828` |
| top strip background | `#0D0D0D` |
| shell fill, centre | `#171717` |

## What is wrong regardless of what the build currently renders

These are faults in the source, not in a screenshot, so they hold whatever
the last build looked like.

### 1. The battery columns are twenty hand-placed coordinates

`qml/components/BatteryColumn.qml` gives every segment its own `x:` and `y:`
literal - 322/395, 304/386, 285/377, 266/367 and so on. There is no pitch,
no spacing, no rule. The column cannot be nudged, only rewritten twenty
times, and the moment one number is out the whole diagonal is out.

This is the direct cause of "padding and margin issues everywhere": there
are no paddings or margins to correct, only coordinates.

**Fix:** one origin, one step vector, one segment size, and the segments
placed from those by a `Repeater`. Then the whole column moves with one
number and the reference measurements above can be matched exactly.

### 2. The bottom dock is hand-placed too

`qml/components/BottomDock.qml` positions R, P, D, the map icon and the rest
with literal x values - 393, 411, 427, 483, 512, 590. Same problem, same
fix: a row with a spacing.

### 3. Colours bypass the theme

`Theme.qml` holds the palette, and then:

- `TabStrip.qml` fills with `"#1E2224"` and `"#20262A"`
- `SpeedDigits.qml` uses `"#F1F3F3"` and `"#C2DED6"`

A literal is a colour nobody can change from the theme and nobody can find
when the palette moves. Every one of these should be a token, and where the
token does not exist yet it should be added with the measured value.

### 4. The speed reading is three copies of the same text

`SpeedDigits.qml` draws the number three times at `Theme.fontSpeed` - once
for the body, once for a highlight, once for a shade - to fake the gradient
and the drop shadow the reference has. Three texts that must stay in step by
hand is three chances to drift, and it is why the digits look flat rather
than graded.

**Fix:** one text, with the gradient as a shader or a mask over it, and one
shadow.

## What still needs a fresh screenshot

`Claude outputs/ride-layout-vs-reference.png` was made at 12:22.
`qml/components/BatteryColumn.qml` was changed at 15:04 and there has been a
commit since, so every number taken off that picture is stale. Measured
against it, the build was:

- battery columns 17 px too far out on both sides, and 21 to 23 px too tall
- the bottom dock 4 to 7 px too low
- the speed digits about 83 per cent of the reference height, which puts
  `fontSpeed` at roughly 178 rather than 150
- the dock background much too light: `#1D2224` against `#0F1413`
- the top strip background too light and blue: `#14181A` against `#0C0C0B`
- teal on the top strip icons, where the reference draws them grey

Those five are worth re-measuring on a current screenshot before anything is
changed, because some may already be fixed.
