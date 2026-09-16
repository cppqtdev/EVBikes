# 10 · Roadmap and checklist

Step-by-step instructions for every open item: `13-remaining-work-guide.md`. Bluetooth: `11-bluetooth-guide.md`. First Qt for MCUs build: `12-qt-for-mcus-first-build.md`.

## Phase 1 — Desktop prototype (this repo)
- [x] Project structure, CMake + qmlproject, modules
- [x] Theme (colours, fonts, spacing, motion)
- [x] Components: telltales, AMP/RPM bars, speed, gauges, turn card, lanes, alert, call, toast, menu
- [x] Pages: Ride, Navigate, Media, Summary, Tyre, Settings, Lock, Splash
- [x] CAN decoder + DBC, phone-link protocol, alert evaluator
- [x] Simulator with 5 scenarios, host unit tests, QML lint
- [x] Qt 6 desktop build (`desktop/`) runs with a Qt 6.8 kit
- [ ] Open in Qt Creator with Qt for MCUs Desktop kit and fix any version-specific build messages
- [ ] Replace generated icons / bike art with designer exports (same names, white on transparent)
- [ ] Qt Design Studio pass for fine visual polish

## Phase 2 — Board bring-up
- [ ] Choose board and display (see `02-architecture-and-tech-stack.md`)
- [ ] Fill `src/platform/board/PlatformBoard.cpp` (CAN, UART, GPIO, PWM)
- [ ] Handlebar switch → `ClusterInput` through an `EventQueue`
- [ ] Light sensor → night mode + backlight
- [ ] Measure FPS / RAM / flash, move assets to external flash
- [ ] Telltale self-test at key-on

## Phase 3 — Phone app
- [ ] BLE module firmware (transparent GATT ↔ UART bridge, bonding)
- [ ] Pairing overlay + local module messages (0x50 BridgeStatus, 0x51 PairingCode)
- [ ] Android app with Navigation SDK turn-by-turn feed (`mobile-bridge/`)
- [ ] Calls, media, notifications, time sync, heartbeat
- [ ] iOS app

## Phase 4 — Product features
- [ ] Real VCU/BMS DBC mapping
- [ ] Charging screen (time to full, charge power)
- [ ] Trip A/B reset, service reminders, error-code list
- [ ] Document viewer (stopped only), language + units
- [ ] Anti-theft: camera capture on wrong PIN (needs camera hardware)
- [ ] OTA update (signed, A/B)
- [ ] Qt Safe Renderer for telltales (FuSa)
- [ ] Optional: offline map page (`QtLocation.Map` + tile fetcher)

## Design principles check (from your research board)

| Principle | Where it is handled |
|---|---|
| Hierarchy in disclosure | Speed/telltales always; details on pages; menus only when stopped |
| Reduced cognitive load | One page at a time, big numbers, short words |
| Smart connectivity | Phone link (nav, calls, music, notifications) |
| Minimalistic interface | Black background, 4 core colours |
| Audio assistance / adaptive AI | Future: voice prompts through helmet (phone side) |
| Gesture control | Future: hardware dependent; 5-way switch now |
| Adapt over anticipate | Accent follows mode; night mode follows light |
| Less is more | Arrow + distance instead of full map |
| Reliability | Timeouts, safe defaults, critical alerts can't be hidden |
