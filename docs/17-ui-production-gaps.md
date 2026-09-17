# 17 · UI gaps between here and a bike you can ride

Everything below was measured or counted in the tree, not guessed. The
hardware and protocol work lives in `10-roadmap-checklist.md` and
`13-remaining-work-guide.md`; this is only the user interface.

Ordered by what would embarrass you first on a real bike.

---

## A. The UI shows numbers that are not real

A rider cannot tell a fake number from a real one. These read as live data and
are not.

| where | shows | truth |
|---|---|---|
| `BikeStatusPage` | Ride time `92 mins` | literal |
| `BikeStatusPage` | Fuel savings `104 Rs` | literal |
| `BikeStatusPage` | SOC consumed `53 %` | literal |
| `BikeStatusPage` | `50 % Eco / 40 % Normal / 10 % Sport` | three literals |
| `Format.reminderBody` | Insurance renewal `12 November` | literal |
| `MiscPage` | three contacts and three reminders | literals in `Format` |

Three whole pages hold no backend reference at all: **`DigilockerPage`**,
**`PaymentPage`**, **`ProfilePage`** (one reference). They are pictures of
features, not features.

**To close:** every one of these needs a property on a C++ singleton and a
signal behind it. Until then they should not ship, or should be marked as
demo content.

---

## B. Data that stops arriving — closed

The decoder already tracked which node had gone quiet, but nothing that
knowledge reached the screen, so a bus that fell silent at 80 km/h left
80 km/h standing.

What is in place now:

- `VehicleCanDecoder` reports freshness per group: `driveStale()` (vehicle
  control unit or motor), `batteryStale()`, `lampsStale()`. A group counts as
  stale when its node has gone quiet for longer than `kTimeoutMs` (500 ms) and
  also before it has ever spoken, so the cluster starts out honest at power-up
  rather than showing a confident zero.
- `VehicleData.driveStale` / `batteryStale` / `lampsStale` carry it to QML.
  `Backend::periodic` sets them, and `SystemData.poll()` runs that from a
  100 ms timer in `Main.qml`; the old once-a-second `tick()` would have meant
  noticing a dead bus up to a second late.
- The stale look: `NumberReadout` draws dashes in `Theme.textMuted` instead of
  the last figure, `SpeedDigits` shows `--`, the AMP and RPM bars go unlit, the
  hexagon gauge goes dark and its needle drops to a quarter opacity, the charge
  and temperature fills go to zero, and the warning telltale lights.
- The `CommunicationLost` alert already existed and fires off the timeout fault
  code, so the rider also gets "SYSTEM FAULT — stop safely and restart the
  bike".
- Covered by `testStaleness()` in `tests/test_core.cpp` (injected timestamps)
  and by an end-to-end silence in `tests/backend_smoke.cpp`. Both were checked
  by breaking the flag on purpose and watching them fail.

**Still open:** dashes for an unknown speed is the safe reading, but which
behaviour is *allowed* is a homologation question, not a design one. It needs
sign-off for each market before launch.

---

## C. Settings that do not do anything

- **Brightness** is shown on the Customize page and changed by `OK`, but
  nothing in the UI or the platform layer reads `SystemData.brightness`. The
  screen does not get brighter or dimmer.
- **Night mode** changes exactly two colours, `textPrimary` and
  `textSecondary`. The glow, the bars, the housings and every literal colour
  stay at their day values, so night mode is not a night mode.
- **Units are km only.** No mph anywhere. Any market that needs miles cannot
  use this build.

---

## D. Rendering and sharpness, what is left of the class

Several faults this session came from one habit: art built at one times, or
with a filter that does not preserve an edge. The ones found and fixed were
the housing chamfer, the outer border, the boot bar, the charging ring, the
last-ride ring and the premultiplied-alpha fringe. What remains of the same
class:

- **Five masks in `generate_cluster_art.py` are still drawn at one times** and
  then multiplied into other art, so their stair-stepped edges survive into
  the result: lines 237 and 239 (`shell_vignette`), 242 (the centre lift
  ellipse), 856 and the bike masks. Every other line in that file draws at
  `SS` and downsamples.
- **Nineteen text blocks ask for italic with no bold weight.** Only
  `Inter-Bold`, `Inter-BoldItalic`, `Inter-Regular` and `Inter-SemiBold`
  ship - there is no regular italic - so Qt synthesises an oblique by
  shearing the upright face. It is visibly worse than a real italic, and
  eight of the nineteen are the `0` to `140` labels around the hexagon gauge,
  which is the most-looked-at text on that screen. Either ship
  `Inter-Italic` or drop italic where the weight is not bold.
- **Two runtime-scaled images**: `StatCard` and `GlassButton` set a width on
  art that was generated at another size, so it is resampled every frame.

---

## E. Screens nobody has measured

Two of twenty-five screens have been checked against a reference frame: the
classic ride screen and the hexagon speedo. The other twenty-three have never
been compared to anything - including every alert overlay, which is the
screen a rider sees at the worst possible moment.

`tools/uicompare/refcluster.py` plus a frame from `all_frames/` is about ten
minutes per screen. Worth doing for, in order: the three alert overlays, the
pre-ride screen, the charging page, the auth screen.

---

## F. Tests over the UI — closed

The `Shape` import fault this session took the whole application down and was
only found because somebody ran it and read the console. Now:

- `tests/qml_load_test.cpp` walks every type in `ClusterCore`,
  `ClusterComponents`, `ClusterScreens` and `EVBikesApp` straight out of the
  resources, creates each one, and fails on any warning. Nothing is listed by
  hand, so a new file is covered the day it is added. Singletons are asked for
  through the engine instead, since they cannot be instantiated.
- `Main.qml` moved into a QML module of its own (`cluster_app`) so the test can
  load the whole screen tree exactly as the application does.
- `.github/workflows/ci.yml` runs three gates: the static checks
  (`qul_lint.py`, `color_check.py`, and the two generators re-run against a
  clean tree), the host unit tests, then a Qt 6 desktop build and the load
  test. The first run on the runner will probably need the Qt version and the
  system library list adjusted; nothing else in it is machine-specific.

**Still open:** the load test proves every file loads and binds without
complaint. It does not compare what is drawn against the reference frames —
that is still the measuring tools in `tools/uicompare`.

---

## G. Look and feel, smaller measured gaps

- The **bike render** is a different motorcycle from the reference's, and
  sits 13 px wider and 6 px left.
- The **compass glyph** in the dock is a diamond in an ellipse; the reference
  is a north arrow.
- **No soft shadow behind the speed digits.** The reference has one; ours is
  flat. Wants pre-rendered art, not a runtime blur.
- The **bar knee**: `BAR_KNEE_RADIUS` is 30 and applied to the centre line,
  but the segments are cut by straight lines, so the bend can read angular.
- The **hexagon gauge lights three segments at zero**, because `litHalves` is
  `Math.round(3 + clamped / 10)`. There is no zero-speed reference frame to
  check the intent against, so it was left alone.

---

## H. Checkers that exist, and one worth adding

Already in the tree and passing:

- `tools/qul_lint.py` - Qt for MCUs type and import rules, including the
  missing-import and JavaScript-subset rules added this session
- `tools/color_check.py` - dark greys with a colour cast
- `tools/uicompare/refcluster.py`, `measure.py`, `paintshell.py` - measuring
  against reference frames without Qt

Worth adding: a checker for art that is drawn at one times in the generator,
which is the habit behind most of section D.
