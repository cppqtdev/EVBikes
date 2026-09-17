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

## D. Rendering and sharpness — closed

Several faults this session came from one habit: art built at one times, or
with a filter that does not preserve an edge. The ones found and fixed earlier
were the housing chamfer, the outer border, the boot bar, the charging ring,
the last-ride ring and the premultiplied-alpha fringe. The rest of the class:

- **The masks drawn at one times** now go through a `polygon_mask` helper that
  draws at `SS` and downsamples, like every other line in the generator.
  `floor_glow`'s left edge went from a single step of 0 → 165 to a ramp of
  24, 94, 157, 165; `shell_vignette` and `panel_haze` gained the same. Paper-
  rendering the ride screen before and after moves 654 pixels by at most 13
  levels, all of them on those edges: the shapes did not move, the staircases
  went.
- **The missing italic faces are shipped.** `tools/generate_italic_faces.py`
  slants the roman outlines at Inter's own italic angle (-9.4 degrees, the
  figure Inter Bold Italic reports) to build `Inter-Italic` and
  `Inter-SemiBoldItalic`. Measured on a rendered stem, all five italic faces
  now slant 9.73 degrees; advance widths are unchanged and ink differs by
  under 1.5 per cent. `tools/font_check.py` fails the build if a face loses
  its italic partner, and it runs in CI.
- **Nothing is resampled at runtime.** Both images turned out to be drawn at
  their own size, so the audit was wrong about the scaling. The real fault was
  `GlassButton`'s glow: a fixed 320 x 200 halo on buttons from 112 to 273 wide,
  nearly three times the width of the small ones. There are two sizes of glow
  now and the button picks the one that fits.

---

## E. Screens measured — six down

The frame numbers in the generator's comments belong to the old capture. In the
new `all_frames/` the screens are: boot and login around 60–220, the profile
picker 140–160, pre-ride 240–260, the ride screens 280–520, the alert overlays
in the red runs 553–809, the menu pages 980–1140 and the hexagon speedo from
1160. Contact sheets of every twentieth frame are the quickest way to find one.

**Overheat overlay (`frame_0770`).** The screen is laid out about a centre line
at x 655, not the middle of the display; the art was already there but the
centred text was still at 640. "Slow Down!" was 46 px and is 52 (the reference
ink is 296 by 39, Inter Bold at 52 measures 293 by 40) and its colour was
`#E0142A` against the reference's `#D60006`. The warning triangle was 89 by 77
with a thin sharp-cornered outline; the reference is 94 by 93 with rounded
corners and a stroke a tenth of its width, and the redrawn one lands on
x 606..699, y 117..209 exactly. The band behind the title was 310 by 28 and is
256 by 24.

**Crash overlay (`frame_0660`).** Same idea, axis 656. The WARNING ribbon's text
was 20 px where the reference measures 21, the CRASH DETECTED ribbon sat 4 px
right and 3 px low, and the small triangle under the message was 2 px low and
crossed the card's bottom edge.

**Tyre overlay (`frame_0570`).** Axis 645. "TIRE PSI LOW" was 28 px and is 26 —
the reference ink is 170 by 20, which Inter Bold at 26 matches exactly — and its
colour was `#D4203A` where the reference peaks at `#99102F`. "Tire Inflation
Required" was 18 px and is 16. The pressure bar was already right to the pixel.

**Pre-ride (`frame_0260`).** The bike is the side view, 250 by 120 at x 518.
CONNECTED was 18 px where the reference measures 16, its band sat 10 px right,
and the three status chips were 50 square on a 58 pitch against the reference's
46 by 40 on 60.

**Charging (`frame_1000`).** The ring was much too small: the reference's outer
edge runs x 567..738 and y 107..280, an outer radius of 86 about (652.5, 193.5),
where ours was 72 about (645, 192). AUTO TURNOFF was 18 px and is 17, and the
state-of-charge reading sat 7 px high.

**Auth (`frame_0200`).** The fingerprint was drawn on a circle and came out 56
by 63; the reference is 57 by 54, so the arcs are squashed to that ratio and the
print now sits at x 611..667, y 298..351. The progress bar was already measured.

**Still open:** the word "Scan" is not Inter. At the height the reference draws
it (cap 25) Inter measures 77 wide against the reference's 100, and no weight or
plausible tracking closes that — it is a wider, more geometric face. Identifying
and licensing it is a decision, not a measurement. Fourteen screens have still
never been compared to anything, and `frame_0450` shows a sport-mode ride screen
with a route prompt and a quick-action row that this UI does not have at all.

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
- The **hexagon gauge's segment count is right**, and the three-at-zero is the
  design, not a bug. Sampling each of the twenty piece masks against the only
  hexagon frames in the capture (around `frame_1280`, at 20 km/h) shows pieces
  0 to 4 lit and the sixth barely touched: five halves. `Math.round(3 + 20/10)`
  is five, so the formula lands on it exactly. A count proportional to the
  printed 0–140 scale would give three at 20, so the reference must carry an
  offset of its own. There is still no zero-speed or high-speed hexagon frame,
  so the offset's exact size and what happens at the top of the scale are
  unconfirmed.

---

## H. Checkers that exist

All of these run in `.github/workflows/ci.yml` and pass on the current tree:

- `tools/qul_lint.py` — Qt for MCUs type and import rules, including the
  missing-import and JavaScript-subset rules added this session
- `tools/color_check.py` — dark greys with a colour cast
- `tools/font_check.py` — every face the screens ask for is shipped
- `tools/art_check.py` — the one-times habit behind most of section D: a shape
  drawn straight onto a screen-sized canvas, unless a wide blur follows
- `tools/generate_desktop_bridge.py` and `tools/sync_project_files.py` re-run
  against a clean tree, so the generated bridge and the project files cannot
  drift from the headers and the QML
- `tools/uicompare/refcluster.py`, `measure.py`, `paintshell.py` — measuring
  against reference frames without Qt, used by hand rather than in CI
