# What the design board asks for, and what is built

The board is `e78ef1184241333.654f6c4770ddb.webp` in the repository root: the
original HMI case study, 1089 by 16383. Its "Uncomplicate The Journey" section
carries the information architecture, and the pages after it show the finished
screens. This is that architecture checked line by line against the code.

Typography and palette on the board match what is in the tree: Inter, and
`#000000`, `#FEFEFE`, `#6FF0D8`, `#DE5013`.

---

## Start-up and the riding screen

| On the board | Here |
|---|---|
| Bike switched on, splash screen | **Built** — `SplashScreen.qml` |
| No key: press toggle, enter PIN | **Built** — `SystemData::submitPin` |
| Three wrong tries and the bike locks | **Built** — `kMaxPinAttempts` is 3 |
| Connectivity symbols: time, Bluetooth, SIM | **Built** — `StatusCorners` draws Bluetooth, signal and the clock. The board's flow also says "date"; no reference frame shows one, so the frames were followed |
| Speedometer | **Built**, two styles |
| Mode, toggled between Eco, Normal and Sport | **Built** |
| Range, battery per cent, low-battery alert | **Built** |
| Odometer and trip | **Built**, but both are on screen at once. The board has a toggle button that swaps between them; every reference frame shows them together, so the frames were followed |
| Menu widget | **Built** — `MenuCarousel`, nine pages |
| Stand down, symbol clears when lifted | **Built** — `PreRideScreen` |
| Music | **Built** — `MiscPage` music tab |
| Radio station browsing on the scroll wheel | **Not built** — nothing in the tree mentions radio |
| Navigation map | **Built** — `MapView` |
| Telltales | **Built** |
| SOS: contacts added from the app, SOS button, contact dialled, last location sent | **Part built** — the crash card sends an SOS on a cancellable countdown. There is no SOS button on the dock, no contact list from the app, and no "location sent" state |

## Menu, part one

| On the board | Here |
|---|---|
| Accessibility: Fonts | **Not built** |
| Accessibility: Language | **Not built** |
| Accessibility: Units | **Built** — Customize page, kilometres or miles |
| Accessibility: Customise widgets | **Not built** |
| Navigation: pair, choose a destination, widget appears, clears on arrival | **Part built** — the widget appears and clears with the phone's route. Choosing a destination happens on the phone, not the cluster |
| Navigation: favourites, maps stored offline on the bike | **Not built** |
| Motorcycle status: tyre pressure, power consumption, range, battery temperature, errors | **Part built** — every one of those readings exists in `VehicleData` and most are on the riding screen or in an alert, but there is no page that lists them together. `BikeStatusPage` is the savings summary, not this |
| Bluetooth | **Part built** — connection state only |

## Menu, part two

| On the board | Here |
|---|---|
| Connectivity: cellular, answer and end a call | **Built** — `CallScreen` |
| Connectivity: notifications | **Built** — `NotificationToast` |
| Connectivity: quick messaging | **Not built** — no canned replies |
| Display: theme, light and dark | **Built** as day and night |
| Display: speedometer style, analog and digital | **Built** as classic and hexagon |
| Display: brightness, manual | **Built** |
| Display: brightness, automatic | **Not built** — there is no light-sensor signal in the CAN map |
| Display: clock, set timezone or adjust manually | **Not built** — the clock comes from the phone's time sync and cannot be set here |
| Documents: choose one, pinch to zoom | **Part built** — `DigilockerPage` lists three documents; there is no viewer and no zoom |
| Documents: upload from the phone when one is missing | **Not built** |
| General settings: motorcycle info, registration, software update, factory reset, clear cache | **Not built** — none of these exist |

## The board's "Main Features"

| On the board | Here |
|---|---|
| Crash detection that highlights the damaged part, SOS to contacts | **Built** — the crash card tints the struck section of the bike red |
| Critical warnings with protocols (overheating) | **Built** — `OverheatOverlay`, two protocols |
| Anti-theft camera captures | **Built** — `SecurityPage`, arm state and capture count |
| In-vehicle payment | **Demo only** — no payment service exists behind it |
| Motorcycle summary: travelled, fuel saved, carbon, CO2 | **Built** — `BikeStatusPage` |
| Messages and music | **Built** — `MiscPage`, fed over the phone link |
| Tyre pressure warning | **Built** |
| Navigation in the middle of the screen | **Built** |
| App, smartwatch and helmet ecosystem, geo-fencing, servicing history | **Out of scope here** — these are companion apps, not cluster firmware |

---

## Where the board and the reference frames disagree

The frames are the later artefact and they win where the two differ, which is
worth recording because the board reads as a fuller specification:

- The board's flow toggles between trip and odometer; every frame shows both.
- The board's flow lists a date beside the time; no frame draws one.
- The board's riding screen carries a side-view bike on an ellipse. The photo
  render in `assets/source/bike.png` is a three-quarter view and is what the
  ride screen uses; the alert and pre-ride screens use the side view.
