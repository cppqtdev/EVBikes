# 14 · Which board to buy for learning + how to design phone navigation

---

## Part 1 — Important before buying: your computer

- **Qt for MCUs runs on Windows or Linux hosts only.** The Qt for MCUs 2.12 prerequisites page lists Linux and Windows. **macOS is not listed.**
- On your Mac you can keep using the **Qt 6 desktop build** (`desktop/`) to learn the UI.
- To build and flash a real board you need one of:
  - a **Windows 10/11 PC** (x86-64) — simplest, all vendor tools work (Infineon TRAVEO kits are Windows-only),
  - a **Linux PC** (Ubuntu LTS, x86-64),
  - a VM on an **Intel** Mac.
- A VM on Apple Silicon (M1/M2/M3/M4) is **not a safe choice**: the Qt for MCUs host tools are built for x86-64, and USB debug probes often misbehave in VMs. Check with Qt support before relying on it.

---

## Part 2 — Board choices (all from the official Qt for MCUs 2.12 list)

**Tier 1** = reference target (best tested). **Tier 2** = verified target.

| Board | Tier | Screen | OS | Radio | Rough price | Good for |
|---|---|---|---|---|---|---|
| **STM32H750B-DK** (ST Discovery kit) | 1 | 4.3" 480×272 touch (built in) | Bare metal | none | about USD 150 on ST eStore | **Best first board**: cheap, display included, Tier 1 |
| **ESP32-S3-BOX-3** (Espressif) | 2 | 2.4" 320×240 touch (built in) | FreeRTOS (ESP-IDF) | **Wi-Fi + BLE built in** | about USD 50 | Cheapest way to learn Qt for MCUs **and** BLE on one board. Very small RAM (512 KB SRAM) and screen |
| **MIMXRT1170-EVKB** (NXP) + **RK055HDMIPI4MA0** 5.5" panel | 1 | 5.5" 720×1280 (buy panel separately) | FreeRTOS | none (M.2 slot for a Wi-Fi/BT card) | check DigiKey / Mouser / Tanotis (India) | **Closest to a real cluster**: 2D GPU, CAN FD, hardware layers, big screen |
| **STM32F769I-DISCO** | 2 | 4" 800×480 touch | Bare metal, FreeRTOS | none | check ST eStore | 800×480 like our design |
| **EK-RA8D1** (Renesas) | 2 | MIPI display kit | Bare metal, FreeRTOS | none | check Renesas | Newer Cortex-M85 |
| **TRAVEO T2G Cluster 4M Lite Kit** (Infineon) | 1 | cluster display kit | Bare metal | none | quote from Infineon/distributor | **Automotive-grade**, Safe Renderer, Navia maps. **Windows host only** |

> Prices change. Check the vendor store or DigiKey/Mouser/element14 India before buying.

### My recommendation

| Your goal | Buy |
|---|---|
| Learn Qt for MCUs cheaply | **STM32H750B-DK** + **ESP32-C3 DevKit** (for BLE, about USD 10) |
| Learn UI + BLE with the fewest parts | **ESP32-S3-BOX-3** (accept small screen; shrink the layout) |
| Build a realistic prototype for this project | **MIMXRT1170-EVKB + RK055HDMIPI4MA0** + **ESP32-C3** + USB-CAN adapter |
| Go towards production | **TRAVEO T2G** kit (after the prototype works) |

### Notes on the STM32H750B-DK + ESP32-C3 combo

- **STM32H750B-DK is on the official Qt list** as a **Tier 1** board (called "STM32H750B-DISCOVERY", **bare metal** only). Qt for MCUs runs on this board.
- **ESP32-C3 is not on the Qt list, and it does not need to be.** It runs no Qt code. It only runs the small Bluetooth bridge sketch from `docs/11` (Arduino + NimBLE) and passes bytes over UART to the STM32.
- Useful board facts (ST product page): 4.3" RGB LCD with capacitive touch, 2 × 512 Mbit Quad-SPI NOR flash (images and fonts go here), 128 Mbit SDRAM, Arduino Uno V3 + STMod+ connectors (UART pins for the ESP32-C3), **2 × CAN FD** (you still need an external CAN transceiver for a real bus), on-board ST-LINK-V3E debugger (no extra probe needed).
- **Bare metal** means no FreeRTOS: CMake uses `src/main.cpp`. Poll the UART ring buffer and buttons from a `Qul` timer or from the main loop instead of an `io` task.
- The screen is smaller than our 800×480 design → see the table below.
- Build/flash needs a **Windows or Linux** PC (Part 1).

### Extra parts for the bench (any board)

| Part | Why |
|---|---|
| ESP32-C3 DevKitM-1 or nRF52840 Dongle | BLE bridge (see `docs/11`) |
| USB-UART adapter, 3.3 V (CP2102/FT232) | Test the phone link without a phone |
| USB-CAN adapter (CANable / PCAN-USB) + CAN transceiver board (TJA1050/SN65HVD230) | Send fake VCU/BMS frames with SavvyCAN + `tools/dbc/evbike.dbc` |
| 5-way navigation switch + push buttons | Handlebar controls |
| Jumper wires, breadboard, 12 V → 5 V buck | Wiring and power |

### Adapting the project to the board screen

| Board | What to change |
|---|---|
| STM32H750B-DK (480×272) | `Theme.screenWidth/Height = 480/272`; scale fixed x/y in `ClusterShell.qml`, `BottomBar.qml`; smaller fonts (speed ~80 px); regenerate frame art (`FRAME_W/H` in `tools/generate_assets.py`) |
| ESP32-S3-BOX-3 (320×240) | Make a **simple layout**: speed + one info line + turn arrow; drop side bars and glow images (RAM) |
| RT1170 (720×1280 portrait) | `MCU.Config { displayRotationAngle: 90 }` → 1280×720 landscape, then centre the 800×480 design or scale up |
| STM32F769I-DISCO (800×480) | No layout change |

---

## Part 3 — How TVS / Royal Enfield style phone navigation works

```
 Rider phone                                    Bike
 ───────────                                    ────
 1. App uses GPS + maps SDK
    (Google Navigation SDK, Mapbox, HERE)
 2. SDK computes route + next turn
 3. App packs only the NEXT TURN:          ──►  4. BLE module receives bytes
    arrow type, distance, road, ETA              5. Cluster parses the frame
    (~30 bytes, about 1 per second)              6. Cluster draws arrow + distance
 7. Voice prompts go phone → helmet              (no map, no GPS on the bike)
    Bluetooth headset (not through the bike)
```

- **The bike never computes the route.** It only shows what the phone says. This keeps the cluster cheap and simple.
- TVS iQube uses **HERE Maps** for its navigation assist; Royal Enfield Tripper uses **Google Maps**. Both use a phone app + Bluetooth.
- Royal Enfield **Tripper Dash** goes further: the phone draws the full map and streams it over **Wi-Fi**. Reviews report phone heating and drops — avoid for v1.

This project already implements the TVS/Tripper-pod method:

| Piece | Where |
|---|---|
| Frame format and maneuver codes | `docs/03-protocols.md`, `src/core/nav/PhoneLinkProtocol.*` |
| Cluster data | `qml/backend/NavigationData.h` |
| Screens | `qml/components/TurnCard.qml`, `LaneGuide.qml`, `qml/screens/NavigationPage.qml`, mini hint in `RidePage.qml` |
| Phone side | `mobile-bridge/android/*` |
| Wiring and firmware | `docs/11-bluetooth-guide.md` |

---

## Part 4 — Designing the navigation experience (UX)

### 4.1 What the rider must see (in 1 glance)

1. **Arrow** (biggest item) — the next maneuver.
2. **Distance to the turn** — rounded so it does not flicker (already in `Format.distanceValue`):
   - ≥ 10 km → whole km · 1–10 km → one decimal · 100–999 m → steps of 50 m · < 100 m → steps of 10 m.
3. **Road name** — short, one line, cut with "…".
4. Small: ETA and distance to destination.
5. Optional: **lane guidance** — highlighted lane.

Everything else (full address, traffic, POI list) stays on the phone.

### 4.2 Screen states

| State | Trigger | Cluster shows |
|---|---|---|
| No phone | link lost > 5 s | "Connect your phone to navigate" |
| Phone, no route | connected, no NavUpdate | "Start a route in the app" |
| Guiding | NavUpdate with maneuver | Turn card + lanes + ETA |
| Turn is near | distance < 100 m | Arrow turns **accent colour**; indicator telltale follows the real lamp |
| Re-routing | phone reports re-route | "Re-routing…" (add a `navState` field, see 4.4) |
| Arrived | maneuver = Destination | Pin icon "Arriving at destination", then clear after 10 s |
| Other page open | rider on Media/Summary | **Mini hint** (small arrow + distance) on Ride page; optionally auto-switch to Navigate when distance < 200 m |

### 4.3 Design rules for riders

- Max **3 pieces of text** on the navigation card.
- Arrow ≥ 96 px, distance ≥ 40 px, bold.
- High contrast (white on black), no map texture behind the arrow.
- No scrolling, no touch input while moving.
- Do not flash; use colour change + (optional) short beep for "turn now".
- Keep indicators separate: the cluster must **never** blink the indicator telltale by itself.

### 4.4 Protocol improvements to add later

| Field | Why |
|---|---|
| `navState` (u8: 0 idle, 1 guiding, 2 rerouting, 3 arrived, 4 GPS lost) | Show the states in 4.2 clearly |
| `nextManeuver` + `distanceBetween` | "then turn left" preview when two turns are close |
| `speedLimitKmh` (u8) | Speed-limit sign next to speed (if the SDK provides it) |
| `destinationName` (text) | Show once at start |

Add them as a new **version 2** of `NavUpdate` (the parser already rejects unknown versions, so old clusters stay safe).

### 4.5 Map SDK choice for the phone app

| SDK | Gives turn data for a small display | Notes |
|---|---|---|
| **Google Navigation SDK** (Android/iOS) | Yes — "turn-by-turn data feed" made for two-wheeler displays | Paid; Google Maps quality in India |
| **Mapbox Navigation SDK** | Yes — banner instructions + route progress | Paid after free tier; custom styling |
| **HERE SDK** | Yes | Used by TVS iQube |
| **OSRM / GraphHopper + OpenStreetMap** | Yes (you run the server) | Free data (ODbL), more work, good for learning |

Always read the SDK terms about showing directions on a vehicle display.

### 4.6 Full map later (Pattern C)

- Qt for MCUs 2.10+ has `QtLocation.Map` with your own tile fetcher (offline tiles on SD card).
- Needs a stronger board (RT1170 or TRAVEO T2G) and storage. See `docs/09-maps-and-mobile-app.md`.
- Qt + Infineon **Navia** reference shows this on TRAVEO T2G.

---

## Part 5 — Learning path (week by week)

| Week | Do | Done when |
|---|---|---|
| 1 | Qt 6 desktop build on your Mac; read docs 01–06 | You can change a colour in `Theme.qml` and see it |
| 2 | Get a Windows/Linux PC; install Qt for MCUs; desktop MCU kit (`docs/12`) | Same UI runs with the MCU desktop kit |
| 3 | Board arrives; flash a Qt for MCUs example, then EVBikes (adapt screen size) | Splash + PIN + ride page on the board |
| 4 | ESP32-C3 BLE bridge + nRF Connect (`docs/11` part D) | Bytes from phone appear on the UART terminal |
| 5 | Board UART driver + `phone_link_sim.py` (`docs/11` part E) | Demo route counts down on the board |
| 6 | Android test app with a button (`docs/11` part G5) | Tapping the button shows a turn arrow |
| 7 | Navigation SDK in the app (`docs/11` part G6) | Real route drives the cluster |
| 8 | CAN adapter + SavvyCAN (`docs/13` item 3a) | Speed on screen comes from CAN |

---

## Sources

- [Qt for MCUs supported platforms](https://doc.qt.io/QtForMCUs/qtul-supported-platforms.html)
- [Qt for MCUs prerequisites (Linux and Windows hosts)](https://doc.qt.io/QtForMCUs/qtul-prerequisites.html)
- [MIMXRT1170-EVKB in Qt for MCUs](https://doc.qt.io/QtForMCUs/qtul-instructions-mimxrt1170-evkb.html)
- [STM32H750B-DK in Qt for MCUs](https://doc.qt.io/QtForMCUs/qtul-instructions-stm32h750b-dk.html) · [ST eStore](https://estore.st.com/en/stm32h750b-dk-cpn.html)
- [ESP32-S3-BOX-3 in Qt for MCUs](https://doc.qt.io/QtForMCUs/qtul-instructions-esp32s3-box3.html) · [Adafruit listing](https://www.adafruit.com/product/5835)
- [RK055HDMIPI4MA0 panel (DigiKey India)](https://www.digikey.in/en/products/detail/nxp-usa-inc/RK055HDMIPI4MA0/16274141) · [Tanotis India](https://www.tanotis.com/products/nxp-rk055hdmipi4ma0-rk055hdmipi4ma0-lcd-panel-5-5-720-x-1280-pixel-controller)
- [Google Navigation SDK turn-by-turn feed](https://developers.google.com/maps/documentation/navigation/android-sdk/tbt-feed)
- [TVS iQube SmartXonnect](https://www.tvsmotor.com/electric-scooters/tvs-iqube/connectivity/smartxonnect) · [Royal Enfield Tripper Dash](https://www.royalenfield.com/in/en/tripper-dash/)
