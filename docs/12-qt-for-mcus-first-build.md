# 12 · First build with Qt for MCUs (when you install it)

Today the project runs with the **Qt 6 desktop kit** (`desktop/` folder).
This guide is for the day you install **Qt for MCUs**. The same CMake file switches to the MCU build by itself when it finds the SDK.

> Honest status: the MCU build has **never been compiled** (no SDK was available while writing it). The code follows the Qt for MCUs 2.12 docs, so expect a few small fixes, not a redesign. This guide lists the likely ones.

---

## Step 1 — Get a licence and install

1. Ask Qt for a **Qt for MCUs evaluation licence** (qt.io → Contact / Try Qt for MCUs). It is a commercial product.
2. Open **Qt Maintenance Tool** (or Online Installer) → *Add or remove components* → **Qt for MCUs → 2.12.x** (LTS):
   - ✅ *Desktop* (Qt Quick Ultralite desktop platform)
   - ✅ your board, e.g. *NXP MIMXRT1170-EVKB (FreeRTOS)* or *Infineon TRAVEO T2G*
   - ✅ Qt Design Studio (optional)
3. Install the board tools the Qt for MCUs "Getting started" page lists for your board (compiler + flash tool + vendor SDK).
4. Qt Creator → *Settings → SDKs → MCU*:
   - set the Qt for MCUs SDK path,
   - pick *Desktop* target → **Create Kit**,
   - later pick your board target → fill the tool paths it asks for → **Create Kit**.

**Check**: *Projects* page lists a kit named like `Qt for MCUs 2.12.x - Desktop 32bpp`.

## Step 2 — Open the project with the MCU desktop kit

1. *File → Open Project* → `EVBikes/CMakeLists.txt`.
2. Enable the **Qt for MCUs – Desktop** kit (you can keep the Qt 6.8 kit too; they use separate build folders).
3. *Build → Run CMake*.

**Check**: the General Messages pane does **not** show "Qul not found, building the Qt 6 desktop version". If it does, the kit is not passing `Qul_ROOT` — re-create the kit in step 1.

## Step 3 — Build and fix (likely issues)

Build once. Then compare the errors with this table. Fix one at a time, top to bottom.

| # | Error looks like | Where | Fix |
|---|---|---|---|
| 1 | `'string' file not found` or `std::string` unknown in **qmlinterfacegenerator** | `qml/backend/*.h` | In `qml/backend/backend.qmlproject` add `MCU.includeStdHeaders: true` inside `InterfaceFiles { }` |
| 2 | `Main.h: No such file` | `src/main.cpp`, `src/os/main_freertos.cpp` | Look in the build folder for the generated header of `Main.qml` and use its name/struct |
| 3 | `unknown property "…"` in a `.qmlproject` | `EVBikes.qmlproject` | Remove or rename that property (names differ slightly between versions) |
| 4 | Module not found `ClusterCore` / `ClusterBackend` | `ModuleFiles` | Check the paths in `ModuleFiles.files`; each module `.qmlproject` needs `MCU.Module { uri: ... }` |
| 5 | `Unsupported pixel format Alpha8` | `ImageFiles` | Change `MCU.resourceImagePixelFormat` to `"Automatic"` |
| 6 | `Cannot assign to non-existent property "elide"` / `letterSpacing` / `restart` | a QML file | Remove that line or replace (e.g. `hideTimer.stop(); hideTimer.start()`) |
| 7 | JavaScript error on a function | `qml/core/Format.qml` | Simplify: avoid `var` re-assignment tricks, move logic to C++ |
| 8 | `Keys` does nothing on desktop | `Main.qml` | Make sure the root item has `focus: true`; click the window once |
| 9 | `platforminterface/platforminterface.h` not found | `PlatformBoard.cpp` (board kit only) | Use the header name from your Qt for MCUs version (`qul/platform/...` in some versions) |
| 10 | Duplicate `vApplication…Hook` | FreeRTOS board kit | Remove your hooks (the platform already has them) or theirs |
| 11 | Font glyph missing (box shown) | Text with ₹ ° ₂ • – × | Keep `autoGenerateGlyphs: true`; or replace the symbol with plain text |
| 12 | `QUL_OS` empty / wrong main used | `CMakeLists.txt` | Print it: `message(STATUS "QUL_OS=${QUL_OS} QUL_PLATFORM=${QUL_PLATFORM}")` and adjust the `if()` |

**Check**: the desktop MCU app opens, the PIN screen shows, 1234 unlocks, the arrow keys change pages, M changes the scenario.

### Keep both builds healthy

- Run `python3 tools/qul_lint.py qml` before every commit.
- Run host tests: `cmake -S . -B build/tests -DEVB_BUILD_HOST_TESTS=ON && cmake --build build/tests && ctest --test-dir build/tests`.
- A new QML file → add to the module `.qmlproject` **and** the module `CMakeLists.txt`.
- A change in `qml/backend/*.h` → run `python3 tools/generate_desktop_bridge.py`.
- Something works in Qt 6 but not in Qt for MCUs → the Qt for MCUs rule wins (see `docs/06`).

## Step 4 — Board kit

1. Choose the board kit, *Run CMake*, build.
2. The build now uses:
   - `src/os/main_freertos.cpp` (if the kit is FreeRTOS),
   - `src/platform/board/PlatformBoard.cpp` (hardware drivers — TODOs).
3. Screen size:
   - Check your panel: `Qul::Platform` / board docs.
   - RT1170-EVKB panel is 720×1280 portrait → either set `displayRotationAngle: 90` in `MCU.Config` (and keep 800×480 design centred), or change `Theme.screenWidth/Height` and the fixed x/y values in `ClusterShell.qml`, `BottomBar.qml`, `generate_assets.py` (`FRAME_W/H`).
4. Flash: connect the debug USB → **Run** in Qt Creator.

**Check**: splash → PIN → ride page on the board display. Demo mode moves the needles.

## Step 5 — Measure on the board

Add the profiling overlay for one test run:

```qml
// in Main.qml (test builds only)
import QtQuickUltralite.Profiling

QulPerfOverlay {
    anchors.right: parent.right
    anchors.top: parent.top
}
```

and in `EVBikes.qmlproject`: `ModuleFiles { MCU.qulModules: ["Profiling"] }`.

Targets to aim for:

| Metric | Target |
|---|---|
| Frame rate while riding page updates | ≥ 30 FPS (60 FPS ideal) |
| Boot to first frame | < 1 s (telltale self-test must start within this) |
| RAM (heap + stack high-water) | < 70 % of available |
| Flash (app + assets + fonts) | < 70 % of available |

If FPS is low: see `docs/08-optimization-and-safety.md` (Alpha8 images, fewer blended layers, hardware layers).

## Step 6 — When something is unclear

Send the **first** error from *Compile Output* (not the whole log), plus:
- Qt for MCUs version,
- kit name,
- the file and line.
