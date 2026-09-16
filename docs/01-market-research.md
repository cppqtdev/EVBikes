# 01 · How Indian bikes show navigation on the cluster

Short answer: **the phone does the map work, the bike only shows the result.**
There are 3 common ways to do it.

## The 3 patterns

| Pattern | What the cluster shows | Link | Cluster hardware needed | Used by |
|---|---|---|---|---|
| **A. Turn-by-turn (TBT)** | Arrow + distance + road name + ETA (Estimated Time of Arrival) | BLE (Bluetooth Low Energy) | Small MCU (Microcontroller Unit), segment or small TFT (Thin-Film Transistor) screen | TVS SmartXonnect bikes/scooters, Royal Enfield Tripper pod, Bajaj, Hero, most budget bikes |
| **B. Phone-rendered full map (projection)** | Full Google Map picture sent from the phone | Wi-Fi (video/image stream) + BLE (control) | MCU/MPU with image decoder, Wi-Fi chip | Royal Enfield Tripper Dash (Himalayan 450, Guerrilla 450) |
| **C. On-board full map** | Map drawn by the cluster itself | Cellular (eSIM) or offline tiles | MPU (Microprocessor Unit) running Android/Linux, 1–2 GB RAM | Ather (Google Maps on Android-based dash), Ola (MoveOS) |

## What each brand does (public information, Sept 2026)

- **TVS SmartXonnect** (Ntorq, Raider, Apache, Jupiter, iQube)
  - Phone app "TVS Connect" pairs over Bluetooth.
  - Cluster shows turn-by-turn arrows, call / SMS alerts, phone battery, ride stats.
  - iQube: "Navigation Assist" uses **HERE Maps**, plus crash/fall alert, geofencing, anti-theft, live tracking (telematics).
- **Royal Enfield Tripper (pod)**
  - Separate small round screen. Google Maps based. Phone app sends turn-by-turn over BLE.
- **Royal Enfield Tripper Dash** (4-inch round TFT)
  - Full Google Maps view **projected from the phone**. The cluster creates a Wi-Fi SSID; the app connects to it.
  - Day/night auto mode with light sensor, music control with joystick, call and SMS alerts.
  - Known pain points from reviews: phone screen must stay on, phone heats up in sun, drains battery, connection drops.
- **Ather 450** — Android-based 7-inch touch dashboard with on-board Google Maps (vector maps).
- **Bajaj Chetak (2026 update)** — Google Maps with full-map view and turn-by-turn on the TFT.
- **Ola S1** — MoveOS (Android based) with on-board navigation.

## What this means for our project (Qt for MCUs)

- **Start with Pattern A (turn-by-turn).** It is cheap, safe, reliable, and works on any Qt for MCUs board.
- **Pattern C is possible later** on Qt for MCUs 2.10+ with the `Map` QML type + **offline map tiles** (from SD card / eMMC). It needs a stronger board (e.g. Infineon TRAVEO T2G, NXP i.MX RT1170) and a tile source. Qt and Infineon show this in the "Navia" reference.
- **Pattern B** (video projection) needs Wi-Fi + JPEG decoding. Avoid for v1: most user complaints come from this.

## Features to match (from these bikes + our research canvas)

- Speed, ride mode (Eco / Normal / Sport), drive state (P/R/N/D), power (AMP) and RPM bars
- Battery %, range, odometer, trip, battery / motor temperature
- Telltales: indicators, high/low beam, ABS (Anti-lock Braking System), warning, battery fault, side stand
- Turn-by-turn navigation + ETA + lane guidance
- Call alert (answer / reject), SMS / app notification, music control
- Tyre pressure (TPMS — Tyre Pressure Monitoring System) with low-pressure alert
- Overheat alert with "Slow down" protocol, crash detection with SOS
- Ride summary: km travelled, fuel money saved, CO₂ saved
- PIN lock / anti-theft, clock, day/night theme, brightness

## Sources

- [Royal Enfield Tripper Dash](https://www.royalenfield.com/in/en/tripper-dash/)
- [Rushlane – Tripper Dash review](https://www.rushlane.com/royal-enfield-himalayan-450-tripper-dash-review-post-feb-21st-fota-update-12489262.html)
- [Tripper navigation – Wikipedia](https://en.wikipedia.org/wiki/Tripper_navigation_system)
- [TVS iQube SmartXonnect](https://www.tvsmotor.com/electric-scooters/tvs-iqube/connectivity/smartxonnect)
- [TVS Raider SmartXonnect](https://www.tvsmotor.com/media/blog/exploring-tvs-raider-smartxonnect)
- [DriveSpark – scooters with inbuilt navigation (2026)](https://www.drivespark.com/two-wheelers/2026/top-electric-scooters-with-inbuilt-navigation-ather-ola-tvs-vida-bajaj-084095.html)
- [Bajaj Chetak Google Maps update](https://www.bajajauto.com/corporate/media-centre/press-releases/chetak-upgrades-its-portfolio-with-new-in-built-features-including-google-maps)
- [Qt for MCUs 2.12 LTS (Navia maps reference)](https://www.qt.io/blog/qt-for-mcus-2.12-lts-released)
