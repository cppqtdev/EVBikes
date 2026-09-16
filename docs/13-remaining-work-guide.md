# 13 · Remaining work: how to do each item

This is the "learn and implement" companion to `10-roadmap-checklist.md`.
Each item has: **why**, **steps**, **code to start from**, and **how to check**.
Suggested order = the order of this document.

---

## 1. First Qt for MCUs build
- **Why**: prove the Ultralite code compiles.
- **How**: follow `docs/12-qt-for-mcus-first-build.md`.
- **Check**: desktop MCU kit runs the same UI as the Qt 6 kit.

---

## 2. Bluetooth end to end
- **Why**: navigation, calls and music need the phone.
- **How**: follow `docs/11-bluetooth-guide.md` parts B → G.
- **Check**: a test button in the Android app shows a turn arrow on the cluster.

---

## 3. Board bring-up (drivers)

All in `src/platform/board/PlatformBoard.cpp`. Use your vendor SDK examples (`flexcan`, `lpuart`, `gpio`, `pwm` for NXP).

### 3a. CAN bus

**Steps**
1. Transceiver + 120 Ω termination on the bench.
2. Init CAN at 500 kbit/s.
3. Acceptance filter: only IDs in `src/core/can/CanIds.h`.
4. RX interrupt → copy into `evb::CanFrame` → `Backend::postCanFrameFromIsr(frame)`.

**NXP FlexCAN sketch** (check names against your SDK version):

```cpp
#include "fsl_flexcan.h"

static flexcan_handle_t g_canHandle;
static flexcan_frame_t g_rxFrame;
static flexcan_mb_transfer_t g_rxXfer;

static FLEXCAN_CALLBACK(canCallback)
{
    if (status == kStatus_FLEXCAN_RxIdle) {
        evb::CanFrame f;
        f.id = g_rxFrame.id >> CAN_ID_STD_SHIFT;    // standard 11-bit ID
        f.dlc = g_rxFrame.length;
        const uint32_t w0 = g_rxFrame.dataWord0;   // bytes are big-endian inside the word
        const uint32_t w1 = g_rxFrame.dataWord1;
        for (int i = 0; i < 4; ++i) {
            f.data[i] = uint8_t(w0 >> (24 - 8 * i));
            f.data[4 + i] = uint8_t(w1 >> (24 - 8 * i));
        }
        f.timestampMs = evb::platform::millis();
        Backend::postCanFrameFromIsr(f);
        FLEXCAN_TransferReceiveNonBlocking(base, &g_canHandle, &g_rxXfer);   // re-arm
    }
}
```

- Simpler and faster for many IDs: use the **Rx FIFO / enhanced Rx FIFO** with an ID filter table.
- TRAVEO T2G: `Cy_CANFD_Init` + receive callback; STM32: `HAL_FDCAN_ConfigFilter` + `HAL_FDCAN_RxFifo0Callback`.

**Check**: send `VCU_Status` from a USB-CAN tool (SavvyCAN + `tools/dbc/evbike.dbc`) → speed changes on screen. Stop sending → after 0.5 s the warning telltale turns on (fault `0x0101`).

### 3b. Handlebar buttons (5-way + mode + back)

**Why an EventQueue?** `ClusterInput::inject()` emits a QML signal. It must run on the UI thread.

```cpp
// src/backend/ButtonQueue.cpp (new)
#include "ClusterInput.h"
#include <qul/eventqueue.h>

struct ButtonEvent { int button; int action; };

class ButtonQueue : public Qul::EventQueue<ButtonEvent>
{
public:
    void onEvent(const ButtonEvent &e) override { ClusterInput::instance().inject(e.button, e.action); }
};

ButtonQueue &buttonQueue()
{
    static ButtonQueue q;
    return q;
}
```

In the `io` task (every 10 ms), per button:

```cpp
static evb::Debouncer okDebounce(3);          // 3 × 10 ms = 30 ms
static uint32_t okPressedAt = 0;
static bool okLongSent = false;

bool ok = okDebounce.update(GPIO_PinRead(BOARD_OK_GPIO, BOARD_OK_PIN) == 0);   // active low
if (ok && okPressedAt == 0) { okPressedAt = now; okLongSent = false; }
if (ok && !okLongSent && now - okPressedAt >= 800) {
    buttonQueue().postEvent({ClusterInput::Ok, ClusterInput::LongPress});
    okLongSent = true;
}
if (!ok && okPressedAt != 0) {
    if (!okLongSent)
        buttonQueue().postEvent({ClusterInput::Ok, ClusterInput::Press});
    okPressedAt = 0;
}
```

- Repeat for each button (make a small `ButtonTracker` struct to avoid copy-paste).
- Add `ButtonQueue.cpp` to `EVB_BACKEND_SOURCES` in `CMakeLists.txt` and `desktop/CMakeLists.txt`.

**Check**: each button changes pages / menus like the keyboard does on desktop.

### 3c. Backlight + light sensor (day/night)

```cpp
// io task, every 100 ms
static evb::EmaFilter lux(3);
const int value = lux.update(readLightSensorAdc());     // your ADC read
// hysteresis: night below 200, day above 300 (tune on the bike)
static bool night = false;
if (!night && value < 200) night = true;
if (night && value > 300) night = false;
// post to UI thread (another tiny EventQueue, like ButtonQueue) → SystemData::instance().nightMode.setValue(night)
```

- `platform::setBacklight(percent)`: set PWM duty. Night → about 30 %, day → 100 %.
- **Check**: cover the sensor → text dims and backlight drops.

---

## 4. Real vehicle signals
- **Why**: our DBC is a template.
- **Steps**
  1. Get the DBC (or a signal list) from the VCU, BMS, motor controller, ABS and TPMS suppliers.
  2. Update `src/core/can/CanIds.h` and the `switch` in `VehicleCanDecoder.cpp`. Keep scaling to integers.
  3. Update `tests/test_core.cpp` with real example frames (capture them with a CAN logger).
  4. Update `tools/dbc/evbike.dbc` or replace it with the supplier's file.
- **Check**: host tests pass; logged frames replayed from SavvyCAN show correct values.

---

## 5. Cluster → vehicle commands (trip reset, ride mode request)
- **Why**: the cluster must ask the VCU; it never changes vehicle state by itself.
- **Steps**
  1. Define a CAN message, e.g. `0x601 CLUSTER_Request` (`u8 cmd`: 1 = reset trip A, 2 = next ride mode).
  2. Add `bool sendCanFrame(const CanFrame &)` to `PlatformIo.h` (board: FlexCAN send; sim: forward to `Simulator`).
  3. Add `void resetTrip()` to `VehicleData` (or a new `VehicleCommands` singleton) that builds and sends the frame.
  4. Add a `MenuRow` "Reset trip" in `SettingsPage.qml`; handle it in `Router.activateSetting()`; raise `settingsCount`.
- **Check**: VCU (or simulator) sets TripA to 0 and the cluster shows 0.0 km.

---

## 6. Telltale self-test at key-on
- **Why**: many regulations require warning lamps to light at start so the rider knows the bulbs work.
- **Steps**: in `TelltaleBar.qml` add a test flag and OR it into every `on:`:

```qml
Row {
    id: bar

    property bool selfTest: true

    Timer {
        interval: 1500
        running: true
        onTriggered: bar.selfTest = false
    }

    Telltale {
        source: "qrc:/assets/icons/26/abs.png"
        on: bar.selfTest || VehicleData.absFault
        onColor: Theme.telltaleAmber
    }
    // ... same "bar.selfTest ||" for the others
}
```

- Make sure `SplashScreen` does **not** cover the telltales during those 1.5 s (e.g. keep the splash only in the centre zone, or start the self-test when the splash fades).
- **Check**: all telltales on for 1.5 s after boot, then real states.

---

## 7. Charging screen
- **Why**: EV riders look at the cluster while charging.
- **Data**: `VehicleData.chargeState`, `batteryPercent`, `packCurrentAx10`, `packVoltageX10`. Add `timeToFullMin` (new CAN signal from BMS) if available.
- **Steps**
  1. New `qml/screens/ChargingPage.qml` (big battery %, a `LinearGauge`, charge power `V × A / 100` kW, time to full).
  2. Show it automatically: in `ClusterShell.qml` put it above the pages with `visible: VehicleData.chargeState === VehicleData.Charging`.
  3. Add the file to `screens.qmlproject` and `qml/screens/CMakeLists.txt`.
  4. Simulator: add a 6th scenario "Charging" in `Simulator.cpp` (`ChargingState = 1`, current negative).
- **Check**: M key reaches the charging scenario and the page appears.

---

## 8. Service reminders and error-code list
- **Steps**
  1. `SystemData`: add `Qul::Property<int> serviceDueKm` (value from VCU or stored).
  2. Show a small amber chip on the Ride page when `odometerKm >= serviceDueKm - 100`.
  3. Error list: keep the last 8 fault codes in a fixed array in C++ (`FaultLog`), expose via a `Qul::ListModel` and show in a `ListView` page (stopped only).
- **Check**: simulator fault → appears in the list with its code.

---

## 9. Language and units
- **Language**
  1. All texts already use `qsTr()`.
  2. Create `translations/evbikes_hi.ts` (Hindi) etc. with `lupdate`, translate in Qt Linguist.
  3. Add `TranslationFiles { files: ["translations/evbikes_hi.ts"] }` to `EVBikes.qmlproject` (MCU) and `qt_add_translations` (Qt 6).
  4. Hindi needs a font with Devanagari (e.g. Noto Sans Devanagari) and possibly `complexTextRendering: true` (Monotype Spark engine) — check the licence and memory.
- **Units (km ↔ miles)**
  1. `SystemData.useMiles` property.
  2. Convert in `Format.qml` (`km * 0.621`), never in the decoder.

---

## 10. Watchdog and safe fallback
- **Steps**
  1. Enable the hardware watchdog (e.g. NXP `RTWDOG`) with 1–2 s timeout.
  2. Kick it from a place that proves the UI is alive: the 1 s `SystemData.tick()` sets a flag; the `io` task kicks the watchdog only if the flag was set, then clears it.
  3. Critical telltales that must survive a UI hang → **Qt Safe Renderer** (`SafeImage`) on a supported board (TRAVEO T2G).
- **Check**: add a test menu item that runs `for(;;){}` in the UI → board resets within 2 s.

---

## 11. Real PIN storage and anti-theft
- **Steps**
  1. Store a **hash** of the PIN (e.g. SHA-256 with a device-unique salt) in a flash sector / EEPROM emulation — never the plain PIN.
  2. `SystemData::submitPin` compares hashes; keep the 3-try limit; add a lock-out time (e.g. 5 min) stored in flash so a reboot does not reset it.
  3. App command to set / reset the PIN over the secured BLE link (new message type, e.g. `0x42 SetPin`, payload hash).
  4. Remove the "(demo PIN 1234)" text in `LockScreen.qml`.
- **Check**: wrong PIN 3× → locked, reboot → still locked.

---

## 12. Release configuration
- **Steps**
  1. `Simulator.cpp`: `running.setValue(false)` by default; or only compile `Simulator.cpp` in desktop builds and remove its `Timer` from `Main.qml` via a separate `DemoDriver.qml` listed only in desktop builds.
  2. `SystemData.cpp`: `demoMode` false.
  3. Build type `MinSizeRel` for the board; enable resource checksum verification (Qt for MCUs `enableResourceChecksumVerification`).
  4. Remove `QulPerfOverlay`.
- **Check**: fresh flash shows real data only.

---

## 13. OTA (Over-The-Air) software update
- **Plan**
  1. Bootloader with **A/B slots** (MCUboot is a good open-source choice).
  2. Images **signed** (ECDSA); bootloader verifies before running.
  3. Transfer path: phone app → BLE (new message types for chunks, with CRC and resume) → module → UART → cluster writes to the inactive slot. Or via the VCU if it has a telematics modem.
  4. After reboot the new image must confirm itself (e.g. after 30 s healthy), else the bootloader rolls back.
  5. Assets (images, fonts) can be in a separate partition (`MCU.resourceStorageSection`) so small UI changes are small updates.
- **Check**: flash v1, update to v2 over BLE, power-cut during update → still boots v1.

---

## 14. Design polish
- **Steps**
  1. Ask the designer for icons as **white on transparent PNG**, one file per size used (`assets/icons/<size>/`, `assets/turns/<size>/`), same file names as `assets/`.
  2. Bike artwork: 260×150 white silhouette.
  3. Frame glow: 800×480 white glow (or re-run `tools/generate_assets.py` after changing `bezel_points()`).
  4. Open the `.qmlproject` in **Qt Design Studio** to fine-tune positions visually (Design Studio understands Qt for MCUs projects).
  5. Re-generate `docs/screen-preview.html` with `python3 tools/build_screen_preview.py` for reviews.
- **Check**: side-by-side with the Figma/Behance design.

---

## 15. Hardware choices
| Decision | Options | Notes |
|---|---|---|
| MCU board | NXP i.MX RT1170, Infineon TRAVEO T2G, Renesas RH850/D1, STM32H7 | Pick one in the current Qt for MCUs supported list |
| Display | 5–7 inch TFT, 800×480, IPS, high brightness, optical bonding | Sunlight readable, −20…+70 °C |
| BLE | Pre-certified nRF52 or ESP32-C3 module | See `docs/11` |
| Power | 12 V → 5 V/3.3 V automotive buck, load-dump protection | ISO 7637 transients |
| Connectors | Sealed automotive (IP67) | Vibration |

---

## 16. Safety and legal
- ISO 2575 telltale symbols and colours (already followed in the theme).
- India: check CMVR (Central Motor Vehicle Rules) requirements for two-wheeler instrument clusters with your homologation team (ARAI / ICAT testing).
- Functional safety (ISO 26262) assessment: decide which telltales are safety relevant → Qt Safe Renderer.
- Distraction: keep the rules in `docs/08` (menus only when stopped, no message text while moving).

---

## 17. Licences
| Item | Licence | Action |
|---|---|---|
| Qt for MCUs | Commercial | Buy per-device / development licence |
| Qt 6 (desktop preview) | LGPL / commercial | Fine for development |
| Inter font | SIL OFL | Keep `assets/fonts/Inter-LICENSE.txt` |
| Google Navigation SDK | Commercial (Google Maps Platform) | Check pricing and vehicle-display terms |
| NimBLE / nRF Connect SDK | Apache 2.0 / Nordic 5-clause | Keep notices |
| OpenStreetMap data (future map) | ODbL | Show attribution |

---

## Progress tracker

Copy this into your notes and tick as you go:

```
[ ] 1  First Qt for MCUs build (desktop kit)
[ ] 2  BLE module firmware + nRF Connect test
[ ] 2  Pairing overlay + local messages (0x50/0x51)
[ ] 2  Android test app (button → turn arrow)
[ ] 3a CAN driver + bench test with USB-CAN
[ ] 3b Buttons through EventQueue
[ ] 3c Backlight + light sensor
[ ] 4  Real DBC mapping + tests
[ ] 5  Trip reset / ride-mode request
[ ] 6  Telltale self-test
[ ] 7  Charging page
[ ] 8  Service reminder + fault list
[ ] 9  Language + units
[ ] 10 Watchdog (+ Safe Renderer)
[ ] 11 PIN storage
[ ] 12 Release config
[ ] 13 OTA
[ ] 14 Design polish
[ ] 15 Hardware selection
[ ] 16 Safety / legal review
[ ] 17 Licences
```
