# 17 · UI gaps between here and a bike you can ride

Everything below was measured or counted in the tree, not guessed. The
hardware and protocol work lives in `10-roadmap-checklist.md` and
`13-remaining-work-guide.md`; this is only the user interface.

Ordered by what would embarrass you first on a real bike.

---

## A. Numbers that were not real — closed

What the trip page claimed, and where it comes from now:

- **Ride time, SOC consumed and the Eco / Normal / Sport split** were the
  literals `92 mins`, `53 %` and `50 / 40 / 10`. A new `TripData` singleton
  measures them: moving time and time per ride mode accumulated against the
  clock, state of charge remembered from the moment the bike first moved, and
  the whole lot reset when the rider zeroes the bike's own trip counter. Before
  the bike has moved the page shows `--` rather than a figure.
- **Fuel savings** was `104 Rs`. Both the lifetime card and the trip card now
  divide by one named figure, `petrolRupeesPerKm`, so they cannot disagree. It
  is still an assumption, and it is labelled as one: it wants to become a
  setting the owner can correct for their fuel price.
- **Contacts and reminders** were six strings inside `Format.qml`. They arrive
  over the phone link now, as message `0x13 ListEntry` (documented in
  `docs/03-protocols.md`), three slots per list, held in `PhoneListData`. The
  simulator sends the sample rows so the demo still shows something. An
  unpaired phone leaves the lists empty and the page says so; the link going
  quiet clears them, so nothing about the rider stays on screen after their
  phone has gone.
- **Rider names** were `JASH`, `RISHI`, `KEVIN`. They are `SystemData`
  properties now, empty until somebody enrols a profile, and the screen shows
  `RIDER 1` and so on until then.
- **`PaymentPage` and `DigilockerPage`** have no service behind them and cannot
  get one here. They carry a `DEMO` badge in demo mode, and outside demo mode
  their sample content is not drawn at all — a shipped cluster will not show a
  document or a toll that does not exist.

**Still open:** the payment and document pages need a real service before they
mean anything; the demo notice only stops them from lying in the meantime.

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

## C. Brightness and night mode — closed, units still open

Both now work through one mechanism. The cluster is drawn on black, so a black
layer over the whole screen at opacity *a* scales every lit pixel by *1 - a*:
that is a real dim, not a grey wash.

- **Brightness.** `setBrightnessLevel` already pushed the value to
  `platform::setBacklight`, but the board driver is a stub and the desktop panel
  has no backlight at all, so nothing happened. `platform::hasBacklight()` says
  which case a target is in; where there is no backlight the picture is dimmed
  instead, over the full 10–100 range the setting allows. `Backend::init` also
  pushes the stored level at start-up, so the first frame is at the level the
  rider left it.
- **Night mode** takes a further step down on top of that, alongside the two
  text colours it already shifted.
- **A critical alert goes back to full brightness.** A crash card at twenty per
  cent is no use to anybody.

**Still open:** units are km only. No mph anywhere, so any market that needs
miles cannot use this build.

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
