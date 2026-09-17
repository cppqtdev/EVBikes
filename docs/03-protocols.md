# 03 · Protocols: how the cluster reads speed, indicators, battery, RPM and navigation

The cluster gets data from **2 places**:

- **CAN bus** (Controller Area Network) — everything about the bike.
- **Phone link** (BLE, Bluetooth Low Energy) — navigation, calls, music, time.

Plus a few direct wires (GPIO — General Purpose Input/Output): handlebar switch, light sensor, backlight PWM (Pulse Width Modulation).

---

## 1. CAN bus

### Basics

- 500 kbit/s, 11-bit IDs, Intel (little-endian) byte order, 120 Ω termination at both ends.
- Transceiver on the cluster board, e.g. TJA1042 / TCAN1042.
- Use **hardware acceptance filters** so the MCU only receives the IDs below.
- The file `tools/dbc/evbike.dbc` has the same table — open it in SavvyCAN, BusMaster, Vector CANdb++ or `cantools`.

### Who sends what

| Node | Full name | Sends |
|---|---|---|
| VCU | Vehicle Control Unit | speed, ride mode, drive state, ready, side stand, crash, ambient temp, odometer, faults |
| MCU | Motor Control Unit (motor controller) | motor RPM, phase current, motor / controller temperature |
| BMS | Battery Management System | state of charge, voltage, current, pack temperature, charging state, range |
| BCM | Body Control Module (or VCU) | indicators, high/low beam, hazard |
| ABS | Anti-lock Braking System | ABS fault, ABS active |
| TPMS | Tyre Pressure Monitoring System | front / rear pressure |

> Real bikes: get the DBC (CAN database) from your VCU/BMS supplier and map their signals in `VehicleCanDecoder.cpp`. Only that one file changes.

### Message table

| ID | Name | Len | Period | Signal | Start bit | Bits | Scale / offset | Unit |
|---|---|---|---|---|---|---|---|---|
| 0x101 | VCU_Status | 4 | 20 ms | VehicleSpeed | 0 | 16 | ×0.1 | km/h |
| | | | | RideMode | 16 | 3 | 0 Eco, 1 Normal, 2 Sport | |
| | | | | DriveState | 19 | 2 | 0 P, 1 R, 2 N, 3 D | |
| | | | | ReadyToRide | 21 | 1 | | |
| | | | | SideStandDown | 22 | 1 | | |
| | | | | CrashDetected | 23 | 1 | | |
| | | | | AmbientTemp | 24 | 8 | −40 | °C |
| 0x102 | MCU_Status | 6 | 20 ms | MotorSpeed | 0 | 16 | ×1 | rpm |
| | | | | PhaseCurrent | 16 | 16 signed | ×0.1 | A |
| | | | | MotorTemp | 32 | 8 | −40 | °C |
| | | | | ControllerTemp | 40 | 8 | −40 | °C |
| 0x201 | BMS_Status | 8 | 100 ms | StateOfCharge | 0 | 10 | ×0.1 | % |
| | | | | ChargingState | 10 | 2 | 0 none, 1 charging, 2 done, 3 fault | |
| | | | | PackVoltage | 16 | 16 | ×0.1 | V |
| | | | | PackCurrent | 32 | 16 signed | ×0.1 | A |
| | | | | PackTemp | 48 | 8 | −40 | °C |
| 0x202 | BMS_Range | 2 | 1 s | RangeEstimate | 0 | 16 | ×1 | km |
| 0x301 | BCM_Lamps | 1 | 50 ms + on change | IndicatorLeft / Right / HighBeam / LowBeam / Hazard | 0..4 | 1 each | | |
| 0x302 | ABS_Status | 1 | 100 ms | AbsFault / AbsActive | 0..1 | 1 each | | |
| 0x401 | TPMS_Status | 4 | 1 s | FrontPressure / RearPressure | 0 / 16 | 16 | ×0.1 | psi |
| 0x501 | VCU_Odometer | 8 | 1 s | Odometer / TripA | 0 / 32 | 32 | ×0.1 | km |
| 0x7A0 | VCU_Faults | 2 | on change | FaultCode | 0 | 16 | | |

### Decoding rules (already in code)

- Values are kept as **scaled integers** (e.g. speed ×10) — no floating point in the hot path.
- A signal is pushed to the UI **only when it changes**.
- **Timeout 500 ms** per node → safe default + fault code (`0x0101` VCU lost, `0x0102` motor lost, `0x0201` BMS lost). Cleared automatically when the node comes back.
- Indicator telltales follow the **real lamp state** from CAN. The cluster never makes its own blinking.
- Ride mode is **requested** by the rider switch → VCU decides → cluster shows what VCU reports.

### How the bits are read

```cpp
// src/core/can/CanFrame.h
uint32_t canGetBitsLE(const uint8_t *data, uint8_t startBit, uint8_t length);
int32_t  canGetSignedLE(const uint8_t *data, uint8_t startBit, uint8_t length);
```

---

## 2. Phone link (BLE)

### Hardware

- A small BLE module (e.g. Nordic nRF52832/nRF52840, ESP32-C3, or the Wi-Fi/BT combo chip on your board) runs a **GATT server** and passes bytes to the MCU over **UART 115200 8N1**.
- The module is a "transparent bridge": it does not understand the frames, it only moves bytes.

### GATT service

| Item | UUID | Properties | Direction |
|---|---|---|---|
| Phone Link service | `6f7e0001-7a3c-4f1b-9e2d-45b1c0de0001` | — | — |
| RX characteristic | `6f7e0002-7a3c-4f1b-9e2d-45b1c0de0001` | Write Without Response | phone → cluster |
| TX characteristic | `6f7e0003-7a3c-4f1b-9e2d-45b1c0de0001` | Notify | cluster → phone |

- Request **MTU 185** after connect. Frames larger than MTU−3 are split; the parser joins them again.
- Use **LE Secure Connections bonding** (pairing with numeric comparison shown on the cluster).

### Frame format (all little-endian)

```
 byte 0      1         2          3..4          5 .. 5+len-1     last 2
 [SOF=A5] [ver=01] [msgType] [len (u16)] [payload .......] [CRC16 (u16)]
```

- CRC-16/CCITT-FALSE (poly 0x1021, init 0xFFFF) over bytes 1 .. end of payload.
- Max payload 160 bytes. Text = 1 length byte + UTF-8 bytes (max 48, cut on a character boundary).
- Bad CRC / bad header → frame dropped, parser searches for the next `A5` (self-sync).

### Messages

| Type | Name | Direction | Payload |
|---|---|---|---|
| 0x01 | NavUpdate | phone → cluster | `u8 maneuver, u8 roundaboutExit, u32 distToManeuver_m, u32 distRemaining_m, u16 eta_min, u8 laneMask, u8 recommendedLaneMask, text roadName` |
| 0x02 | NavStop | phone → cluster | — |
| 0x10 | CallState | phone → cluster | `u8 status (0 idle, 1 ringing, 2 active), text caller` |
| 0x11 | MediaState | phone → cluster | `u8 playing, u8 volume, u16 position_s, u16 duration_s, text title, text artist` |
| 0x12 | Notification | phone → cluster | `u8 appId, text sender, text message` |
| 0x13 | ListEntry | phone → cluster | `u8 list (0 contacts, 1 reminders), u8 slot (0..2), text title, text text` |
| 0x20 | TimeSync | phone → cluster | `u32 unixSeconds, i16 utcOffsetMinutes` |
| 0x21 | PhoneStatus | phone → cluster | `u8 battery%, u8 signalBars, u8 internet` |
| 0x30 | Heartbeat | both | — (send every 2 s; link is "lost" after 5 s of silence) |
| 0x40 | MediaCommand | cluster → phone | `u8 cmd (1 play/pause, 2 next, 3 previous)` |
| 0x41 | CallCommand | cluster → phone | `u8 cmd (1 answer, 2 reject)` |

ListEntry carries one row of a list the phone owns. The cluster keeps three
slots per list and draws whatever it was last sent; a slot outside that range is
treated as a bad frame. Sending an empty title clears the row, and the link
going quiet clears both lists, so nothing about the rider stays on screen after
their phone has gone.

### Maneuver codes

| Code | Name | Code | Name |
|---|---|---|---|
| 0 | None | 9 | U-turn right |
| 1 | Straight | 10 | Roundabout enter (use `roundaboutExit`) |
| 2 | Slight left | 11 | Roundabout exit |
| 3 | Left | 12 | Fork left |
| 4 | Sharp left | 13 | Fork right |
| 5 | Slight right | 14 | Merge left |
| 6 | Right | 15 | Merge right |
| 7 | Sharp right | 16 | Destination |
| 8 | U-turn left | | |

### Example frame (NavUpdate: right turn in 250 m on "MG Road")

```
a5 01 01 16 00 06 00 fa 00 00 00 70 30 00 00 17 00 00 00 07 4d 47 20 52 6f 61 64 17 8f
```

Generate more with `python3 tools/phone_link_sim.py --dump`.

### Why a custom binary protocol?

- Small (≈30 bytes per update) → fits in one BLE packet after MTU exchange.
- No JSON parser on the MCU, no heap.
- Versioned (`ver` byte) → old clusters ignore new versions safely.

---

## 3. Direct inputs and outputs

| Signal | Pin type | Handling |
|---|---|---|
| Handlebar 5-way switch + Mode + Back | GPIO with interrupt | Debounce 30 ms (`evb::Debouncer`), long press 800 ms → `ClusterInput.inject(button, action)` |
| Ambient light sensor | ADC (Analog to Digital Converter) or I²C | Filter (`EmaFilter`), hysteresis → `SystemData.nightMode` + backlight |
| Backlight | PWM | `platform::setBacklight()` |
| Ignition / wake | GPIO | Board power-up logic |

Desktop keyboard mapping (simulator): arrows = joystick, Enter = OK, Esc/Backspace = Back, **M = next demo scenario**.
