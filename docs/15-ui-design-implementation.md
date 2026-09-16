# 15 · UI design implementation (reference screens → Qt for MCUs)

The reference is the video frames in `screens/` (ride, menu, alerts) and `screen2/` (splash).
This page explains how each screen was rebuilt **only with Qt Quick Ultralite components**.

## 1. Canvas and coordinates

- Screen: **1280 × 480** (wide cluster panel, e.g. 10.25" bar display).
- Mapping from the reference: frames are 1920 × 1080 → scale to **1280 × 720**, then **subtract 125 px from y**.
  Example: the speed "57" top in the reference is at y 258 (1280 scale) → **y 133** on our screen.
- All positions in QML are absolute `x/y` numbers taken from that mapping, so you can compare pixel by pixel.
- Other panels: change `Theme.screenWidth/Height` and regenerate the art with a new `SHELL` polygon in `tools/generate_cluster_art.py`.

### Measured frame geometry (from `frame_010` and `frame_020`)

| Part | Screen coordinates (left half, the right half is mirrored at x 1280) |
|---|---|
| Login / splash body (`SHELL`) | top corner (142, 35) → side point (81, 138) → (159, 369) → bottom (351, 462) |
| Top housing | top edge x 362–938 at y 4, bottom edge x 436–882 at y 54 (the reference is 10 px right of centre) |
| Ride glow line (`RIDE_GLOW`) | (147, 43) → (88, 150) → (163, 369) → bottom (350, 457) → (416, 406) → flat to x 545 |
| Bar centre line | top (122, 110) → knee (200, 338) → end (360, 419), 35 px wide |
| Bar segments | **8** per side; the cut lines are listed in `BAR_CUTS` (outer point, inner point) |

Map route: one image per turn type (`route_straight/left/right/slight_*/sharp_*/uturn_*/roundabout/destination.png`).
Every route starts at the tip of the arrow cursor and ends pointing the same way as the turn arrow; `Format.routeImage()` picks it from `NavigationData.maneuver`.

Check your changes against the reference with an overlay: scale the reference frame to 1280 × 720, crop y 125–605,
and put it on top of a screenshot of the app at 50 % opacity.

## 2. Components used (all in the Qt for MCUs 2.12 list)

| Need | Component |
|---|---|
| Shell, housings, glows, bar segments, cards, ribbons | `ColorizedImage` (Alpha8 PNG tinted at runtime) |
| Bike pictures, seat, album art, payment card | `Image` (colour PNG, drawn at native size) |
| Gradients on cards, bars, buttons, chips, lines | `Rectangle.gradient` (vertical and `Gradient.Horizontal`) |
| Rings (charging, trip summary) | `Shape` + `ShapePath` + `PathArc` (module `Shapes`) |
| Needle, rotated panels, callout line | `Rectangle` + `transform: Rotation` |
| Two-tone speed digits | Same `Text` three times inside clipped `Item`s |
| Lists (documents, messages, reminders) | `ListModel` + `Repeater` |
| Animations | `Behavior`, `NumberAnimation`, `ColorAnimation`, `Timer` |
| Screen flow | `visible`/`opacity` bindings (no `Loader.item`, no dynamic objects) |

**Not possible in Qt for MCUs, and what we do instead**

| Reference effect | Replacement |
|---|---|
| Blur behind the tyre card | Dark card at 94 % opacity over the ride screen |
| Photo backgrounds (city street) | 3D terrain grid (`terrain.png`) — photos cost too much flash and hurt readability |
| Neon glow | Pre-blurred white PNG tinted with `ColorizedImage` |
| Text glow | `glow_blob_<w>x<h>.png` behind the text |
| 3D bike render | Original drawn bike art (`bike_*.png`) — replace with your own renders |

## 3. Screen-by-screen

| Reference frames | Screen | File(s) | How it works |
|---|---|---|---|
| `screen2/splash_0001…0100` | Splash: bike front drawn line by line, headlight turns on | `SplashScreen.qml` | 8 stroke images `front_line_0..7.png` appear one after another (220 ms `Timer`), then `front_headlight.png` fades in |
| `splash_0110…0150`, `frame_005` | Logo + fingerprint + loading bar | `SplashScreen.qml`, `BootChrome.qml` | Text logo, `fingerprint.png` on a disc, progress `Rectangle` with gradient and `progress_glow.png` |
| `frame_010/011` | Rider profiles (JASH, RISHI, KEVIN) | `AuthScreen.qml` | `avatar_106/92.png`; ← → selects (`SystemData.selectProfile`) |
| `frame_012–015` | Scan → No access (red floor) → Match (teal floor) | `AuthScreen.qml`, `ShellFrame.qml` | `SystemData.authState`; `floor_glow.png` tinted red/teal; spinner = 8 dots with rotating opacity |
| `frame_016/018` | Side stand alert / Connected | `PreRideScreen.qml` | `glow_alert.png` (3 stacked lines) red or teal, callouts `callout.png`, line = rotated `Rectangle` |
| `frame_019–021` | Ride (Eco) | `RideView.qml`, `SpeedDigits.qml`, `BikeOrbit.qml`, `TripCounter.qml`, `RangeOdoRow.qml`, `BatteryTempBars.qml`, `BottomDock.qml`, `PowerBar.qml`, `RpmBar.qml` | Bars = 10 generated segment images each; lit count from power / RPM |
| `frame_022–025` | Navigation | `MapView.qml` | `terrain.png` + `route.png` + `nav_cursor.png`; banner with road, turn icon, distance; mic / recentre / layers buttons |
| `frame_026–034` | Sport mode | `Theme.qml` | `Theme.sport` changes `glow`, `segLow/segHigh`, speed shade and chip text |
| `frame_029–031` | Explore actions | `MapView.qml` | Shown when no route is active |
| `frame_038/039` | Tyre PSI low | `TyreAlertOverlay.qml` | Card + bike with red rear wheel (`bike_110_wheel.png`) + pressure scale |
| `frame_043–045` | Crash detected | `CrashOverlay.qml` (phase 0) | `card_wide`, gold `Ribbon`, bike with red rear (`bike_200_rear.png`), red ribbon |
| `frame_046/047` | SOS countdown | `CrashOverlay.qml` (phase 1) | `AlertData.sosSecondsLeft` counts down in C++; → cancels (`AlertData.cancelSos`) |
| `frame_050–052` | Over heating, "Slow Down!" | `OverheatOverlay.qml` (phase 0) | Red `GlowBand`, bike + triangle, gold "PROTOCOLS" ribbon |
| `frame_053/054` | Protocol buttons | `OverheatOverlay.qml` (phase 1) | Two `GlassButton`s, ↑ ↓ select, OK activates (`AlertData.activateProtocol`) |
| `frame_058–063` | Menu: Digilocker | `MenuCarousel.qml`, `DigilockerPage.qml` | Carousel shows previous / current / next; ↑ ↓ scroll documents |
| `frame_064–066` | Menu: Seat | `SeatPage.qml` | `seat.png` moves with `SystemData.seatLevel`; OK = RESET |
| `frame_067/068` | Menu: Charging | `ChargingPage.qml` | `Shape` ring, `ToggleSwitch` for auto turn-off |
| `frame_069–074` | Menu: Bike status + trip ring | `BikeStatusPage.qml`, `StatCard.qml`, `TripStat.qml` | OK switches to the trip ring (4 `ShapePath` arcs) |
| `frame_075/076` | Menu: Security | `SecurityPage.qml` | `shield.png`, red "Anti-Theft Captures" with badge, "Activation" toggle |
| `frame_077/078` | Menu: Payment | `PaymentPage.qml` | Generic card art (no bank branding), CONFIRM → PAID |
| `frame_079` | Menu: Customize → Shortcut keys | `CustomizePage.qml` | `TabStrip` + rotated panels and icons; theme tab holds the settings list |
| `frame_080–085` | Menu: Misc → music / message | `MiscPage.qml`, `MessageRow.qml` | Tabs; message text hidden while moving |
| `frame_086–088` | Hexagon speedometer | `HexSpeedoView.qml`, `HexGauge.qml` (generated) | 10 segments cut in halves (`hex_piece*.png`) so the fill stops at the needle, needle angle from a table, tall battery column, map; toggle with ↑ or Customize → theme |
| `frame_089/090` | Shutdown | (not yet) | Reuse `BootChrome` with decreasing progress |

## 4. Controls (desktop keyboard = handlebar switch)

| State | ← → | ↑ ↓ | OK (Enter) | Back (Esc) |
|---|---|---|---|---|
| Profiles | choose rider | — | scan finger | — |
| Pre-ride | — | — | continue (stand must be up) | — |
| Riding | bike ⇄ map | ↑ speedometer style | open menu (≤ 5 km/h) | back to bike |
| Menu | previous / next item | page action | page action | close |
| Tyre / other warning | — | — | dismiss | — |
| Crash countdown | → cancel SOS | — | — | — |
| Overheat protocols | — | choose | activate | — |

`M` = next demo scenario (City Eco → Sport → Low tyre → Overheat → Crash).
`P` = park the demo bike (speed goes to 0 and stays there; press again to ride). The menu only opens at 5 km/h or less,
so park first; pressing OK while moving shows "Stop the bike to open the menu".

Desktop preview window (Qt 6 build only, `desktop/main.cpp`):

- **Frameless and transparent**: only the cluster frame is drawn; the desktop shows through around it.
- **Move it**: press the left mouse button anywhere in the window and drag.
- **Quit**: `Q`, or `Ctrl+Q` (`Cmd+Q` on macOS).

## 5. Regenerating art and file lists

```bash
python3 tools/generate_assets.py        # icons, turn arrows, glow blobs (only the sizes the QML uses)
python3 tools/generate_cluster_art.py   # shell, bars (+ PowerBar.qml / RpmBar.qml), cards, bike art
python3 tools/sync_project_files.py     # .qmlproject + CMake lists
python3 tools/qul_lint.py qml           # Qt for MCUs component check
```

### Image sizes: Qt for MCUs does not scale images

- `Image` and `ColorizedImage` are always drawn at the **size of the PNG**. `width`/`height` do not stretch them.
- So the size is part of the path: `qrc:/assets/icons/28/bluetooth.png` is a 28 × 28 icon, `glow_blob_320x160.png` is 320 × 160.
- Write the path you need in QML (with `Icon { size: 28 }` matching the folder), then run `generate_assets.py`: it reads the QML and draws exactly those files.
- The desktop preview draws images at their own size too, so it looks like the board.

## 6. Replacing the art with your own

- Keep the **same file names and sizes** in `assets/cluster/`.
- Single-colour art: **white on transparent**, it is tinted in QML.
- Colour art (bike renders): put your render at `assets/source/bike.png` (transparent background, any size) and run
  `generate_cluster_art.py`. It makes `bike_110/180/200/260.png` (width × ¾ width) and the red masks
  (`*_rear.png`, `*_wheel.png`). Move the masks with `BIKE_REAR_WHEEL` / `BIKE_REAR_PART` at the top of the bike section.
  The big source file stays out of the firmware because only `assets/cluster/` is packed.
- If the reference design belongs to another designer, get their permission (or their source files) before using their exact renders in a product.
