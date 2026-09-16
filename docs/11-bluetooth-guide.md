# 11 · Bluetooth guide: from zero to navigation on the cluster

This guide takes you step by step from "nothing connected" to "the phone sends turn arrows to the cluster".
Read it in order. Every step ends with a **check**, so you know it works before moving on.

---

## Part A — Learn the basics (10 minutes)

### Words you will see

- **BLE (Bluetooth Low Energy)**: the low-power Bluetooth used by watches, fitness bands and bike clusters. Not the same as "classic" Bluetooth used for music headsets.
- **Central**: the device that scans and connects. Here: **the phone**.
- **Peripheral**: the device that advertises and waits. Here: **the bike** (the BLE module).
- **Advertising**: the peripheral shouts "I am here, I offer service X" a few times per second.
- **GATT (Generic Attribute Profile)**: the "table" of data a peripheral offers once connected.
  - **Service**: a group of data, identified by a **UUID** (Universally Unique Identifier, a 128-bit ID).
  - **Characteristic**: one value inside a service. It has **properties**: Read, Write, Write Without Response, Notify.
  - **Notify**: the peripheral pushes new data to the phone without the phone asking.
  - **CCCD (Client Characteristic Configuration Descriptor)**: the switch the phone writes to turn notifications on.
- **MTU (Maximum Transmission Unit)**: the largest packet. Default 23 bytes (20 bytes of data). We ask for 185.
- **Pairing / bonding**: pairing makes an encrypted link; bonding **saves the keys**, so next time it reconnects without asking.
- **LE Secure Connections + passkey**: the cluster shows a 6-digit code, the rider types it on the phone. This blocks strangers.
- **UART (Universal Asynchronous Receiver-Transmitter)**: a simple 2-wire serial link (TX and RX) between two chips.

### Our design (already decided in `docs/03-protocols.md`)

```
┌──────────── Phone (Central) ────────────┐
│ Android app                              │
│  Navigation SDK → NavUpdate frame        │
│  writes frames to RX characteristic      │
│  receives notifications from TX          │
└───────────────────┬──────────────────────┘
                    │ BLE (encrypted, bonded)
┌───────────────────▼──────────────────────┐
│ BLE module (Peripheral)  ESP32-C3/nRF52   │
│  "transparent bridge": bytes in = bytes out│
└───────────────────┬──────────────────────┘
                    │ UART 115200 8N1 (TX, RX, GND)
┌───────────────────▼──────────────────────┐
│ Cluster MCU (Qt for MCUs)                 │
│  UART ISR → ring buffer → io task         │
│  → Backend::postPhoneBytes → link::Parser │
│  → NavigationData / PhoneData → QML       │
└───────────────────────────────────────────┘
```

| Item | Value |
|---|---|
| Service UUID | `6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001` |
| RX characteristic (phone → bike) | `6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001`, Write Without Response |
| TX characteristic (bike → phone) | `6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001`, Notify |
| Frame | `A5 | ver | type | len(u16) | payload | CRC16` |

**Why a separate BLE module and not the board's own radio?**
- A Bluetooth stack is big and complex. The module runs it; the cluster MCU only reads bytes.
- The same cluster code works with any module.
- You can swap ESP32 ↔ nRF52 without touching the Qt project.

---

## Part B — Learn with zero hardware (today)

### B1. Test the protocol on your Mac

```bash
cd EVBikes
python3 tools/phone_link_sim.py --dump
```

- **Check**: you see 4 hex lines starting with `a5 01`.
- Read `docs/03-protocols.md` and decode one line by hand: `a5` start, `01` version, `01` NavUpdate, `16 00` = 22 bytes payload…

### B2. Watch the simulator use the same path

- Run the app (Qt 6 kit). The simulator builds real frames and pushes them through `Backend::postPhoneBytes()` → `link::Parser` → `NavigationData`.
- Open `src/backend/Simulator.cpp`, find `sendPhoneTraffic()`. This is exactly what the phone app will send.
- **Check**: the Navigate page (→ key) shows "Turn right, MG Road".

### B3. Explore BLE with a free phone app

- Install **nRF Connect for Mobile** (Nordic, Android/iOS). You will use it in Part D to talk to the module before writing any app code.

---

## Part C — Buy and wire the hardware

### C1. Shopping list

| Item | Suggestion | Why |
|---|---|---|
| BLE module (choose one) | **ESP32-C3 DevKitM-1** (Espressif) | Cheap, Arduino/PlatformIO friendly, easiest to learn |
| | **nRF52840 DK** or **nRF52840 Dongle** (Nordic) | Best BLE quality, used in automotive-grade modules |
| USB-UART adapter (3.3 V) | CP2102 / FT232 / CH340 | Talk to the module from your Mac before the board is ready |
| Jumper wires | female-female | |
| Later: automotive module | u-blox NINA-B3 / Nordic-based certified module | Pre-certified radio (saves certification cost) |

### C2. Wiring (3.3 V logic only!)

```
BLE module                 Cluster board (or USB-UART adapter)
──────────                 ───────────────────────────────────
TX  (GPIO21 on C3) ──────► RX  (LPUARTx_RXD)
RX  (GPIO20 on C3) ◄────── TX  (LPUARTx_TXD)
GND ────────────────────── GND
3V3 ◄───── 3.3 V supply (or USB power while learning)
(optional) EN/RESET ◄───── GPIO  (lets the MCU reset the module)
```

- **TX goes to RX** and RX goes to TX (cross over).
- **Never** connect 5 V to a 3.3 V pin.
- Keep wires short (< 20 cm) on the bench; on the bike use a proper connector.

---

## Part D — Firmware for the BLE module (ESP32-C3, Arduino)

### D1. Tools

- Install **Arduino IDE 2** (or VS Code + PlatformIO).
- Boards Manager → install **esp32 by Espressif**. Select *ESP32C3 Dev Module*.
- Library Manager → install **NimBLE-Arduino** (version 2.x). NimBLE is a light BLE stack.

### D2. What the firmware must do

1. Start BLE, create the service with RX + TX characteristics.
2. Advertise the service UUID with the name `EVBike-XXXX`.
3. Phone writes to RX → copy the bytes to UART.
4. UART bytes arrive → send them as TX notifications (split by MTU).
5. Security: bonding + passkey shown on the cluster.
6. Tell the cluster about the link state and the passkey using 2 **local messages** (they never go to the phone):

| Type | Name | Payload | Direction |
|---|---|---|---|
| `0x50` | BridgeStatus | `u8 state` (0 advertising, 1 connected, 2 secured) | module → MCU |
| `0x51` | PairingCode | `u32 passkey` (0 = hide) | module → MCU |

They use the same frame format (`A5 01 50 01 00 <state> <crc>`), so the same parser reads them. Part F shows how to add them to the cluster.

### D3. Sketch `ble_bridge_esp32c3.ino`

> Written for NimBLE-Arduino 2.x. If a callback does not compile, compare with the library's `NimBLE_Server` example — signatures changed between 1.x and 2.x.

```cpp
#include <Arduino.h>
#include <NimBLEDevice.h>

static const char *SERVICE_UUID = "6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001";
static const char *RX_UUID      = "6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001";
static const char *TX_UUID      = "6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001";

static const int UART_RX_PIN = 20;
static const int UART_TX_PIN = 21;
static const uint32_t UART_BAUD = 115200;

static NimBLECharacteristic *txChar = nullptr;
static bool secured = false;
static uint16_t mtuPayload = 20;

// ---- frame helpers (same format as src/core/nav/PhoneLinkProtocol) ----
static uint16_t crc16(const uint8_t *d, size_t n) {
    uint16_t crc = 0xFFFF;
    for (size_t i = 0; i < n; ++i) {
        crc ^= uint16_t(d[i]) << 8;
        for (int b = 0; b < 8; ++b)
            crc = (crc & 0x8000) ? uint16_t((crc << 1) ^ 0x1021) : uint16_t(crc << 1);
    }
    return crc;
}

static void sendLocalFrame(uint8_t type, const uint8_t *payload, uint16_t len) {
    uint8_t f[32];
    f[0] = 0xA5; f[1] = 0x01; f[2] = type; f[3] = len & 0xFF; f[4] = len >> 8;
    memcpy(f + 5, payload, len);
    uint16_t c = crc16(f + 1, 4 + len);
    f[5 + len] = c & 0xFF; f[6 + len] = c >> 8;
    Serial1.write(f, 7 + len);
}

static void sendStatus(uint8_t state) { sendLocalFrame(0x50, &state, 1); }

static void sendPasskey(uint32_t key) {
    uint8_t p[4] = {uint8_t(key), uint8_t(key >> 8), uint8_t(key >> 16), uint8_t(key >> 24)};
    sendLocalFrame(0x51, p, 4);
}

// ---- BLE callbacks ----
class ServerCallbacks : public NimBLEServerCallbacks {
    void onConnect(NimBLEServer *server, NimBLEConnInfo &info) override {
        secured = false;
        sendStatus(1);
        NimBLEDevice::startSecurity(info.getConnHandle());
    }

    void onDisconnect(NimBLEServer *, NimBLEConnInfo &, int) override {
        secured = false;
        sendPasskey(0);
        sendStatus(0);
        NimBLEDevice::startAdvertising();
    }

    void onMTUChange(uint16_t mtu, NimBLEConnInfo &) override {
        mtuPayload = mtu - 3;
    }

    uint32_t onPassKeyDisplay() override {
        uint32_t key = esp_random() % 1000000;
        sendPasskey(key);                     // cluster shows it
        return key;                           // phone must type the same
    }

    void onAuthenticationComplete(NimBLEConnInfo &info) override {
        sendPasskey(0);                       // hide the code on the cluster
        if (!info.isEncrypted()) {
            NimBLEDevice::getServer()->disconnect(info.getConnHandle());
            return;
        }
        secured = true;
        sendStatus(2);
    }
} serverCallbacks;

class RxCallbacks : public NimBLECharacteristicCallbacks {
    void onWrite(NimBLECharacteristic *c, NimBLEConnInfo &) override {
        if (!secured) return;                 // ignore data from unpaired phones
        NimBLEAttValue v = c->getValue();
        Serial1.write(v.data(), v.length());
    }
} rxCallbacks;

void setup() {
    Serial1.begin(UART_BAUD, SERIAL_8N1, UART_RX_PIN, UART_TX_PIN);

    NimBLEDevice::init("EVBike");
    NimBLEDevice::setMTU(185);
    NimBLEDevice::setSecurityAuth(true, true, true);          // bonding, MITM, secure connections
    NimBLEDevice::setSecurityIOCap(BLE_HS_IO_DISPLAY_ONLY);   // we can show a code

    NimBLEServer *server = NimBLEDevice::createServer();
    server->setCallbacks(&serverCallbacks);

    NimBLEService *svc = server->createService(SERVICE_UUID);
    NimBLECharacteristic *rx = svc->createCharacteristic(
        RX_UUID, NIMBLE_PROPERTY::WRITE_NR | NIMBLE_PROPERTY::WRITE);
    rx->setCallbacks(&rxCallbacks);
    txChar = svc->createCharacteristic(TX_UUID, NIMBLE_PROPERTY::NOTIFY);
    svc->start();

    NimBLEAdvertising *adv = NimBLEDevice::getAdvertising();
    adv->setName("EVBike");
    adv->addServiceUUID(SERVICE_UUID);
    adv->enableScanResponse(true);
    adv->start();
    sendStatus(0);
}

void loop() {
    static uint8_t buf[244];
    size_t n = 0;
    while (Serial1.available() && n < sizeof(buf) && n < mtuPayload)
        buf[n++] = uint8_t(Serial1.read());
    if (n > 0 && secured && txChar) {
        txChar->setValue(buf, n);
        txChar->notify();
    }
    delay(2);
}
```

### D4. Check with nRF Connect (no cluster needed)

1. Flash the sketch. Connect a USB-UART adapter to GPIO20/21 and open a serial terminal in **hex mode** (e.g. CoolTerm) at 115200.
2. nRF Connect → Scan → **EVBike** → Connect.
3. Phone asks for a passkey. The terminal shows a frame `A5 01 51 04 00 …` — the 4 bytes after `04 00` are the code (little-endian). Type it on the phone.
4. Terminal shows `A5 01 50 01 00 02 …` = secured.
5. In nRF Connect open the service → RX characteristic → write (type: byte array) one line from `python3 tools/phone_link_sim.py --dump`, without spaces, for example the PhoneStatus frame `a501210300500401fe55`.
6. **Check**: the same bytes appear in the terminal.

### D5. Alternative: nRF52840 (Nordic nRF Connect SDK)

- Install **nRF Connect for VS Code** + nRF Connect SDK.
- Start from the sample **`samples/bluetooth/peripheral_uart`** (Nordic UART Service). It already bridges BLE ↔ UART.
- Change the 128-bit UUIDs to ours (`BT_UUID_128_ENCODE` values in the NUS source or define your own service with `BT_GATT_SERVICE_DEFINE`).
- Enable security in `prj.conf`: `CONFIG_BT_SMP=y`, `CONFIG_BT_SETTINGS=y`, `CONFIG_SETTINGS=y`, `CONFIG_BT_FIXED_PASSKEY=n`.
- Implement `passkey_display` in `bt_conn_auth_cb` → send the `0x51` frame on UART.
- **Check**: same as D4.

---

## Part E — Cluster side: UART driver on the board

The parser, CRC check and UI update already exist. You only fill the driver.

### E1. Rule: do little work in the interrupt

- In the ISR (Interrupt Service Routine): read the byte, put it in a **ring buffer**, return.
- In the `io` task: take bytes from the ring buffer, call `Backend::postPhoneBytes()` in chunks.
- Reason: posting one event per byte from an ISR is slow and can overflow the queue.

### E2. Example for NXP i.MX RT1170 (MCUXpresso SDK, `fsl_lpuart.h`)

> Names like `LPUART1`, the IRQ number and the clock source depend on your board and SDK version. Use the SDK example `lpuart/interrupt` as reference.

```cpp
// src/platform/board/PlatformBoard.cpp (additions)
#include "../../core/util/RingBuffer.h"
#include "fsl_lpuart.h"
#include <FreeRTOS.h>
#include <task.h>

namespace {
evb::RingBuffer<uint8_t, 1024> g_uartRx;
constexpr uint32_t kBleBaud = 115200;
}

extern "C" void LPUART1_IRQHandler(void)
{
    if (LPUART_GetStatusFlags(LPUART1) & kLPUART_RxDataRegFullFlag) {
        const uint8_t byte = LPUART_ReadByte(LPUART1);
        g_uartRx.push(byte);                 // drop on overflow; parser resyncs
    }
    SDK_ISR_EXIT_BARRIER;
}

static void initBleUart()
{
    lpuart_config_t cfg;
    LPUART_GetDefaultConfig(&cfg);
    cfg.baudRate_Bps = kBleBaud;
    cfg.enableTx = true;
    cfg.enableRx = true;
    LPUART_Init(LPUART1, &cfg, BOARD_DebugConsoleSrcFreq()); // use your UART clock
    LPUART_EnableInterrupts(LPUART1, kLPUART_RxDataRegFullInterruptEnable);
    NVIC_SetPriority(LPUART1_IRQn, 5);       // must be >= configLIBRARY_MAX_SYSCALL_INTERRUPT_PRIORITY
    EnableIRQ(LPUART1_IRQn);
}

// Call this from the io task every 10–20 ms (see src/os/main_freertos.cpp)
void evb::platform::pollPhoneLink()
{
    uint8_t chunk[64];
    std::size_t n = 0;
    uint8_t b;
    while (n < sizeof(chunk) && g_uartRx.pop(b))
        chunk[n++] = b;
    if (n > 0)
        Backend::postPhoneBytes(chunk, n);
}

bool evb::platform::sendPhoneBytes(const uint8_t *data, std::size_t len)
{
    LPUART_WriteBlocking(LPUART1, data, len); // fine for small frames; use DMA later
    return true;
}
```

Then:
- Declare `void pollPhoneLink();` in `src/platform/PlatformIo.h` (and an empty version in `sim/PlatformSim.cpp`).
- Call `initBleUart()` from `platform::init()`.
- In `ioTask` (`src/os/main_freertos.cpp`) change the delay to 10 ms and call `evb::platform::pollPhoneLink()`.
- Note: `sendPhoneBytes` is called from the UI task. If other tasks also send, protect it with a mutex.

### E3. Infineon TRAVEO T2G / STM32 in one line each

- TRAVEO: `Cy_SCB_UART_Init` + `Cy_SCB_UART_GetNumInRxFifo` / `Cy_SCB_UART_Get` in the ISR; same ring buffer pattern.
- STM32: `HAL_UARTEx_ReceiveToIdle_DMA` + `HAL_UARTEx_RxEventCallback` → push the received block into the ring buffer.

### E4. Check on the bench

1. Keep demo mode **off** (Settings → Demo mode → Off) so the simulator does not overwrite data.
2. Connect a USB-UART adapter to the board's BLE UART pins.
3. Run `python3 tools/phone_link_sim.py /dev/tty.usbserial-XXXX`.
4. **Check**: the Navigate page counts down the demo route; the Bluetooth icon turns blue.

---

## Part F — Cluster side: pairing code and link state

Add the 2 local messages from D2 so the rider sees the passkey.

### F1. Protocol (`src/core/nav/PhoneLinkProtocol.h`)

```cpp
enum class MsgType : uint8_t {
    // ... existing values ...
    BridgeStatus = 0x50,
    PairingCode = 0x51,
};

class Handler {
public:
    // ... existing ...
    virtual void onBridgeStatus(uint8_t state) { (void)state; }
    virtual void onPairingCode(uint32_t passkey) { (void)passkey; }
};
```

In `Parser::dispatch` (`PhoneLinkProtocol.cpp`):

```cpp
case MsgType::BridgeStatus: {
    const uint8_t s = r.u8();
    if (r.ok()) m_handler.onBridgeStatus(s); else m_handler.onFrameError();
    break;
}
case MsgType::PairingCode: {
    const uint32_t key = r.u32();
    if (r.ok()) m_handler.onPairingCode(key); else m_handler.onFrameError();
    break;
}
```

Add a unit test in `tests/test_core.cpp` (build a frame with `buildFrame`, feed it, check the callback).

### F2. Data for QML (`qml/backend/PhoneData.h`)

```cpp
enum LinkState { Advertising = 0, Connected = 1, Secured = 2 };

Qul::Property<int> linkState;
Qul::Property<int> pairingCode;      // 0 = no pairing in progress
```

In `src/backend/Backend.cpp` → `PhoneHandler`:

```cpp
void onBridgeStatus(uint8_t state) override
{
    PhoneData &p = PhoneData::instance();
    p.linkState.setValue(state);
    if (state != PhoneData::Secured) {
        p.connected.setValue(false);
        NavigationData::instance().clear();
    }
}

void onPairingCode(uint32_t passkey) override
{
    PhoneData::instance().pairingCode.setValue(static_cast<int>(passkey));
}
```

Also change `PhoneQueue::onEvent` so `connected` becomes true only when `linkState == Secured` (local frames from the module must not count as "phone alive").

Then run `python3 tools/generate_desktop_bridge.py` (desktop build).

### F3. Pairing overlay (`qml/components/PairingOverlay.qml`)

```qml
import QtQuick
import ClusterCore
import ClusterBackend

Rectangle {
    id: pairing

    width: 420
    height: 180
    radius: Theme.radiusL
    color: Theme.surfaceRaised
    visible: PhoneData.pairingCode > 0 && VehicleData.speedKmh === 0

    function sixDigits(v) {
        var s = "" + v
        while (s.length < 6)
            s = "0" + s
        return s
    }

    Column {
        anchors.centerIn: parent
        spacing: Theme.spaceM

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Pair your phone")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontBody
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: pairing.sixDigits(PhoneData.pairingCode)
            color: Theme.accent
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontDisplay
            font.bold: true
            font.letterSpacing: 6
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Enter this code on your phone")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontLabel
        }
    }
}
```

- Add it to `components.qmlproject` **and** `qml/components/CMakeLists.txt`.
- Place it in `ClusterShell.qml` inside the centre item: `PairingOverlay { anchors.centerIn: parent }`.
- If `s.length` or `font.letterSpacing` is rejected by Qt for MCUs, pad the number in C++ instead (store a `std::string pairingText`).
- Pair only when stopped (safety). If the bike moves, the module still shows the code on the phone; the rider can pair later.

### F4. Settings entry "Forget phone"

- Add a local command `0x52 BridgeCommand` (`u8 cmd`: 1 = forget all bonds, 2 = restart advertising) cluster → module.
- ESP32: in the UART reader, detect this frame and call `NimBLEDevice::deleteAllBonds()`.
- Cluster: add a `MenuRow` "Forget phone" and a `PhoneData.forgetPhone()` function that calls `Backend::sendToPhone(MsgType::BridgeCommand, ...)`.

---

## Part G — Phone side: Android app

### G1. Create the project

1. Android Studio → *New Project* → *Empty Views Activity*, Kotlin, **minSdk 26**.
2. Package name: `com.evbikes.bridge` (matches the files in `mobile-bridge/android`).
3. Copy the 4 files from `mobile-bridge/android/` into `app/src/main/java/com/evbikes/bridge/`.

### G2. Dependencies (`app/build.gradle.kts`)

```kotlin
dependencies {
    // Google Navigation SDK — check the current version on developers.google.com/maps/documentation/navigation
    implementation("com.google.android.libraries.navigation:navigation:<latest>")
}
```

- Create an API key in Google Cloud with **Navigation SDK** enabled; put it in `AndroidManifest.xml` as `com.google.android.geo.API_KEY` meta-data.
- The Navigation SDK is a paid product. For learning, you can skip it: send test `NavUpdate` frames from a button (see G5).

### G3. Manifest

```xml
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_CONNECTED_DEVICE" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<application ...>
    <service android:name=".NavInfoReceivingService" android:exported="false" />
</application>
```

### G4. Scan and connect (in your Activity or a foreground service)

```kotlin
val scanner = (getSystemService(BLUETOOTH_SERVICE) as BluetoothManager).adapter.bluetoothLeScanner
val filter = ScanFilter.Builder().setServiceUuid(ParcelUuid(ClusterBleLink.SERVICE)).build()
val settings = ScanSettings.Builder().setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY).build()

scanner.startScan(listOf(filter), settings, object : ScanCallback() {
    override fun onScanResult(type: Int, result: ScanResult) {
        scanner.stopScan(this)
        ClusterBleLink.connect(this@MainActivity, result.device)   // Android shows the passkey dialog
    }
})
```

- Ask for `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` at runtime first (`ActivityCompat.requestPermissions`).
- Save `result.device.address` after the first success; next time connect directly with `adapter.getRemoteDevice(address)`.
- Run the BLE link inside a **foreground service** so Android does not stop it while riding.

### G5. First test without the Navigation SDK

```kotlin
button.setOnClickListener {
    ClusterBleLink.send(
        PhoneLinkCodec.navUpdate(
            PhoneLinkCodec.NavUpdate(PhoneLinkCodec.Maneuver.RIGHT, 0, 250, 12400, 23, 0x07, 0x04, "MG Road")
        )
    )
}
```

- **Check**: the cluster Navigate page shows "250 m, Turn right, MG Road".

### G6. Real navigation

- Start guidance with the Navigation SDK (`Navigator.setDestination(...)`, `startGuidance()`).
- Then: `navigator.registerServiceForNavUpdates(packageName, NavInfoReceivingService::class.java.name, 1)`.
- `NavInfoReceivingService` converts each update and sends it (about once per second).
- Add: time sync on connect (already in `ClusterBleLink`), phone status every 30 s, heartbeat every 2 s.

### G7. Calls, music, notifications

| Feature | Android part | Frame |
|---|---|---|
| Incoming call | `TelephonyCallback` (API 31+) or `PhoneStateListener` | `CallState` |
| Answer / reject from cluster | `TelecomManager.acceptRingingCall()` / `endCall()` (needs `ANSWER_PHONE_CALLS`) | receive `CallCommand` |
| Music info | `MediaSessionManager.getActiveSessions()` + `MediaController.Callback` (needs notification-listener access) | `MediaState` |
| Music control | `MediaController.transportControls.play()/pause()/skipToNext()` | receive `MediaCommand` |
| Notifications | `NotificationListenerService.onNotificationPosted` | `Notification` |

---

## Part H — Test with the Mac as the "cluster" (optional, before hardware)

Qt Bluetooth can act as a BLE **peripheral** on macOS. Then a real phone connects to your Mac and the Qt 6 desktop app shows the navigation.

### H1. CMake (`desktop/CMakeLists.txt`)

```cmake
find_package(Qt6 6.5 REQUIRED COMPONENTS Gui Quick Qml Bluetooth)
target_sources(EVBikes PRIVATE MacBlePeripheral.h MacBlePeripheral.cpp)
target_link_libraries(EVBikes PRIVATE Qt6::Bluetooth)
set_target_properties(EVBikes PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist.in)
```

`desktop/Info.plist.in` must contain (macOS asks the user for Bluetooth permission):

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>EVBikes uses Bluetooth to receive navigation from your phone.</string>
```

(Copy the default Qt `Info.plist` template and add these 2 lines.)

### H2. `desktop/MacBlePeripheral.h`

```cpp
#pragma once

#include <QLowEnergyCharacteristic>
#include <QLowEnergyController>
#include <QLowEnergyService>
#include <QObject>
#include <memory>

class MacBlePeripheral : public QObject
{
    Q_OBJECT
public:
    explicit MacBlePeripheral(QObject *parent = nullptr);
    void start();
    bool send(const QByteArray &frame);

private:
    std::unique_ptr<QLowEnergyController> m_controller;
    std::unique_ptr<QLowEnergyService> m_service;
};
```

### H3. `desktop/MacBlePeripheral.cpp`

```cpp
#include "MacBlePeripheral.h"
#include "../src/backend/Backend.h"

#include <QLowEnergyAdvertisingData>
#include <QLowEnergyAdvertisingParameters>
#include <QLowEnergyCharacteristicData>
#include <QLowEnergyDescriptorData>
#include <QLowEnergyServiceData>

namespace {
const QBluetoothUuid kService(QStringLiteral("6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001"));
const QBluetoothUuid kRx(QStringLiteral("6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001"));
const QBluetoothUuid kTx(QStringLiteral("6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001"));
}

MacBlePeripheral::MacBlePeripheral(QObject *parent) : QObject(parent) {}

void MacBlePeripheral::start()
{
    QLowEnergyCharacteristicData rx;
    rx.setUuid(kRx);
    rx.setProperties(QLowEnergyCharacteristic::WriteNoResponse | QLowEnergyCharacteristic::Write);
    rx.setValueLength(0, 244);

    QLowEnergyCharacteristicData tx;
    tx.setUuid(kTx);
    tx.setProperties(QLowEnergyCharacteristic::Notify);
    tx.setValue(QByteArray(1, 0));
    tx.addDescriptor(QLowEnergyDescriptorData(
        QBluetoothUuid::DescriptorType::ClientCharacteristicConfiguration, QByteArray(2, 0)));
    tx.setValueLength(0, 244);

    QLowEnergyServiceData service;
    service.setType(QLowEnergyServiceData::ServiceTypePrimary);
    service.setUuid(kService);
    service.addCharacteristic(rx);
    service.addCharacteristic(tx);

    m_controller.reset(QLowEnergyController::createPeripheral());
    m_service.reset(m_controller->addService(service));

    connect(m_service.get(), &QLowEnergyService::characteristicChanged, this,
            [](const QLowEnergyCharacteristic &c, const QByteArray &value) {
                if (c.uuid() == kRx)
                    Backend::postPhoneBytes(reinterpret_cast<const uint8_t *>(value.constData()),
                                            static_cast<std::size_t>(value.size()));
            });

    connect(m_controller.get(), &QLowEnergyController::disconnected, this, [this] {
        m_controller->startAdvertising(QLowEnergyAdvertisingParameters(), {}, {});
    });

    QLowEnergyAdvertisingData adv;
    adv.setDiscoverability(QLowEnergyAdvertisingData::DiscoverabilityGeneral);
    adv.setLocalName(QStringLiteral("EVBike-Mac"));
    adv.setServices({kService});
    m_controller->startAdvertising(QLowEnergyAdvertisingParameters(), adv, adv);
}

bool MacBlePeripheral::send(const QByteArray &frame)
{
    if (!m_service)
        return false;
    const QLowEnergyCharacteristic tx = m_service->characteristic(kTx);
    if (!tx.isValid())
        return false;
    m_service->writeCharacteristic(tx, frame);   // peripheral role: this sends a notification
    return true;
}
```

### H4. Use it

- In `desktop/main.cpp`: create `MacBlePeripheral ble; ble.start();` after `Backend::init()`.
- Turn demo mode off in the app (Settings → Demo mode → Off).
- In `src/platform/sim/PlatformSim.cpp`, forward `sendPhoneBytes` to the peripheral (e.g. through a function pointer you set from `main.cpp`).
- **Check**: nRF Connect finds **EVBike-Mac**; writing a frame from `phone_link_sim.py --dump` changes the Navigate page.
- Limits: macOS does not let the app control pairing, so there is no passkey here. Use it only for learning.

---

## Part I — Production checklist

- [ ] Encrypted + bonded link required before any data is accepted (module side).
- [ ] Only frames with version `01` accepted (already in parser).
- [ ] Heartbeat every 2 s; link lost after 5 s → navigation cleared (already in `Backend::periodic`).
- [ ] Reconnect automatically (phone: `autoConnect=true`; module: restart advertising).
- [ ] Bond list size limited (e.g. 4 phones); "Forget phone" in settings.
- [ ] Radio certification: use a **pre-certified module** (FCC/CE/WPC-India ETA) to save cost.
- [ ] Antenna away from metal, tested inside the real cluster housing.
- [ ] Current draw in sleep: module in low-power advertising when the bike is off.
- [ ] Firmware update for the module (Nordic DFU / ESP32 OTA) planned.

## Troubleshooting

| Problem | Likely cause | Fix |
|---|---|---|
| Phone does not find the bike | Not advertising, wrong UUID filter | Check with nRF Connect without filter |
| Connects then drops at once | Security failed (`isEncrypted` false) | Delete the pairing on the phone and on the module, try again |
| Frames arrive but UI does not change | Demo mode still on / CRC mismatch | Turn demo off; compare bytes with `phone_link_sim.py --dump` |
| Garbage on UART | Wrong baud rate, TX/RX not crossed, no common GND | Check wiring and 115200 8N1 |
| Only first 20 bytes arrive | MTU not negotiated | `requestMtu(185)` on phone; parser already joins split frames |
| Works on desk, not on bike | Antenna shielded by metal | Move module / external antenna |
