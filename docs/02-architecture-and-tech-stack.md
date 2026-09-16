# 02 · Architecture and tech stack

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| UI (User Interface) framework | **Qt for MCUs 2.12 LTS** (Qt Quick Ultralite) | Long-Term Support, runs on MCUs with little RAM, QML UI, Qt Design Studio flow |
| UI language | QML (Qt Modeling Language), Ultralite subset only | See `06-qt-ultralite-rules.md` |
| Logic | C++17, no exceptions, no RTTI, no heap after start-up | MCU friendly |
| RTOS (Real-Time Operating System) | FreeRTOS (or bare-metal for the simplest boards) | Supported by all Qt for MCUs reference boards |
| Build | CMake 3.21+ with `qul_add_target` + `.qmlproject` | Official Qt for MCUs flow |
| IDE (Integrated Development Environment) | Qt Creator + MCU plugin, Qt Design Studio for UI | Desktop preview + flashing |
| Vehicle bus | CAN 2.0B 500 kbit/s (CAN FD ready) | Standard for VCU, BMS, motor controller |
| Phone link | BLE 5 GATT (Generic Attribute Profile) via a BLE module on UART | Low power, no Wi-Fi needed |
| Phone app | Android (Kotlin) + Google Navigation SDK turn-by-turn feed (or Mapbox) | See `mobile-bridge/` |
| Tests | Host unit tests (CMake + CTest) for all protocol / decode code | Runs on your Mac/Linux without a board |
| Fonts | Inter (SIL Open Font License), Static font engine | Matches the design system |

### Recommended boards

| Stage | Board | Notes |
|---|---|---|
| Desktop | Qt for MCUs **desktop platform** ("Qt" platform) | Fastest loop, uses `Simulator` |
| Prototype | **NXP MIMXRT1170-EVKB** + FreeRTOS | Tier-1 Qt board, 2D GPU, FlexCAN, cheap. Its panel is 720×1280 — set `displayRotationAngle` or adapt `Theme.screenWidth/Height` |
| Production-like | **Infineon TRAVEO T2G** (CYT4DN / CYT3DL / CYTD4EN) | Made for clusters, CAN FD, Qt Safe Renderer for telltales (functional safety), Navia maps reference |
| Low cost | STM32H7 / Renesas RA / RH850 D1 family | Check the current Qt for MCUs supported-platforms list for your exact kit |

## Block diagram

```
 ┌───────────── Bike ─────────────┐        ┌──────── Phone ────────┐
 │ VCU  BMS  MCU(motor)  ABS  TPMS│        │ Nav SDK  Calls  Media │
 └──────────────┬─────────────────┘        └──────────┬────────────┘
                │ CAN 500k                             │ BLE GATT
        ┌───────▼──────┐                       ┌───────▼───────┐
        │ CAN driver   │ ISR                   │ BLE module    │ UART ISR
        └───────┬──────┘                       └───────┬───────┘
                │ Backend::postCanFrameFromIsr         │ Backend::postPhoneBytesFromIsr
        ┌───────▼──────────────────────────────────────▼───────┐
        │   Qul::EventQueue (thread / ISR safe hand-off)        │
        └───────┬──────────────────────────────────────┬───────┘
                │ UI thread                            │ UI thread
        ┌───────▼────────┐                     ┌───────▼────────┐
        │VehicleCanDecoder│                    │ link::Parser   │
        └───────┬────────┘                     └───────┬────────┘
                │ VehicleSignal                        │ NavUpdate / Call / Media
        ┌───────▼──────────────────────────────────────▼───────┐
        │ C++ singletons (Qul::Singleton + Qul::Property)       │
        │ VehicleData  NavigationData  PhoneData  SystemData    │
        │ AlertData (AlertEvaluator)  ClusterInput  Simulator   │
        └───────────────────────────┬───────────────────────────┘
                                    │ property bindings
        ┌───────────────────────────▼───────────────────────────┐
        │ QML: ClusterCore (Theme, Router, Format)              │
        │      ClusterComponents (bars, telltales, cards ...)   │
        │      ClusterScreens (pages, lock, splash, shell)      │
        └───────────────────────────────────────────────────────┘
```

## Key rules of the design

- **Drivers never touch UI objects.** They only post to `Qul::EventQueue`. All property updates happen on the UI thread.
- **Pure C++ core** (`src/core/`) has no Qt includes → unit-tested on the host (`tests/`).
- **One source of truth per value**: CAN → `VehicleData`. QML only reads (and calls a few actions).
- **Simulator uses the real path**: it builds real CAN frames and real phone frames and feeds them to the same decoder. What works on desktop works on the board.
- **Safe defaults on timeouts**: if a CAN node stops (500 ms) the decoder sets a fault code and drops "ready" state; if the phone stops (5 s), navigation is cleared.

## Project structure

```
EVBikes/
├── CMakeLists.txt              qul_add_target + platform selection
├── EVBikes.qmlproject          app config: fonts, images, modules
├── assets/
│   ├── fonts/                  Inter (OFL)
│   ├── cluster/                shell, bar segments, cards, bike and splash art
│   ├── icons/<size>/           white icons at the sizes used in QML (tinted in QML)
│   ├── turns/                  128 px turn arrows
│   └── images/                 soft glow blob
├── qml/
│   ├── Main.qml                root: shell + lock + splash + timers + keys
│   ├── backend/                C++ interface headers → module "ClusterBackend"
│   ├── core/                   Theme, Router, Format singletons → "ClusterCore"
│   ├── components/             reusable widgets → "ClusterComponents"
│   └── screens/                pages and overlays → "ClusterScreens"
├── src/
│   ├── main.cpp                bare-metal / desktop entry
│   ├── os/main_freertos.cpp    FreeRTOS entry (UI task + IO task)
│   ├── backend/                singleton implementations + Backend glue + Simulator
│   ├── core/
│   │   ├── can/                CanFrame, CanIds, VehicleSignals, VehicleCanDecoder
│   │   ├── nav/                PhoneLinkProtocol (frames, CRC, parser)
│   │   ├── alerts/             AlertEvaluator (priority + hysteresis)
│   │   └── util/               RingBuffer, Crc16, EMA filter, Debouncer
│   └── platform/
│       ├── PlatformIo.h        board interface
│       ├── sim/                desktop implementation
│       └── board/              board template (CAN, UART, GPIO, PWM TODOs)
├── desktop/                    Qt 6 desktop build (Qul shims, generated bridge, ColorizedImage)
├── tests/                      host unit tests + backend smoke test (uses desktop/qul_shim)
├── tools/
│   ├── generate_assets.py      re-creates icons and images
│   ├── qul_lint.py             checks QML uses only Ultralite types
│   ├── generate_desktop_bridge.py  qml/backend/*.h → desktop/bridge/QulQmlBridge.*
│   ├── generate_cluster_art.py 1280×480 shell, bars (+ generated PowerBar/RpmBar.qml), cards, bike art
│   ├── sync_project_files.py   keeps .qmlproject and CMake file lists in sync
│   ├── phone_link_sim.py       sends phone frames over serial
│   └── dbc/evbike.dbc          CAN database
├── mobile-bridge/              Android reference code (Kotlin)
└── docs/                       these documents
```

## Threading model (FreeRTOS)

| Task | Priority | Does |
|---|---|---|
| CAN RX ISR | interrupt | Reads frame → `postCanFrameFromIsr` |
| UART RX ISR | interrupt | Reads bytes → `postPhoneBytesFromIsr` |
| `io` task | high | Slow polling (light sensor, GPIO switch debounce) |
| `ui` task | normal | `Qul::Application::exec()` — decode, bindings, rendering |

## Data update rates

| Data | Bus rate | UI rate |
|---|---|---|
| Speed, RPM, power | 20 ms | property changes only when value changes (decoder filters duplicates) |
| Battery, temps | 100 ms | same |
| Telltales | 50 ms + on change | same |
| Navigation | ~1 s | same |
| Clock / housekeeping | — | 1 s (`SystemData.tick`) |
