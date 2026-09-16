# 08 · Optimization and things to take care of

## Performance (keep 60 FPS where possible, never below 30)

- **Only update changed values.** The CAN decoder already skips duplicates. Speed text changes at most once per km/h.
- **Hidden pages are not drawn** (`visible: opacity > 0`). Keep it this way.
- **Use images, not shapes, for glows and decorations.** `Shape` is drawn in software on many boards.
- **Alpha8 + ColorizedImage** for all single-colour art (1 byte/pixel).
- **Avoid big blended layers.** Every semi-transparent pixel costs a blend. Keep full-screen transparent images to 1–2.
- **Use hardware layers** (`QtQuickUltralite.Layers`) on boards that support them: static frame in an `ImageLayer`, moving parts in an `ItemLayer`.
- **Text**: use `StaticText` for labels that never change; limit fonts to 4 files; enable glyph cache priming.
- **No per-frame JavaScript.** Bindings only. Keep functions in `Format.qml` small.
- **Animations**: animate opacity / x / y / colour. Do not animate `width` of big items every frame (only the small bar fills here).
- **Timers**: one 50 ms timer (simulator only) + one 1 s timer. No other periodic timers.
- **Measure** with `QulPerfOverlay` and the Qt for MCUs performance logging on the real board.

## Memory

- No `new` / `malloc` after start-up. Queues and buffers are fixed size (`RingBuffer`, `PhoneChunk`).
- Put images and fonts in external flash (`MCU.resourceStorageSection`), load big ones `OnDemand`.
- Check the linker map after each asset change. Remove unused icons.
- `Loader` for rare, heavy screens (e.g. a future map page) to save RAM.
- UI task stack: start with 32 KB, check high-water mark with `uxTaskGetStackHighWaterMark`.

## Rider safety (most important)

- **Glance time**: every screen must be readable in < 2 seconds. Big speed, few words.
- **Lock menus while moving** (`Router.menuAllowed`, speed ≤ 5 km/h).
- **Hide message text while moving** (only "X sent a message").
- **Telltales always visible** on every page, never covered by popups (popups are inside the centre zone only).
- **Critical alerts cannot be dismissed**; warnings can, and come back if the condition returns.
- **Stale data must never look fresh**: CAN timeout → fault + "ready" off; phone timeout → navigation cleared.
- **Indicators mirror the real lamp state** from CAN (no fake blinking).
- **Sunlight**: aim for a high-brightness panel (around 1000 cd/m² is common for sunlight-readable displays), optical bonding, anti-glare; UI is white-on-black with large type.
- **Night**: auto-dim to avoid blinding the rider.
- **Startup time**: telltale self-check (all on for 1–2 s) within 1 s of key-on is a common legal requirement — add it to the splash on the board.

## Functional safety (FuSa) and regulations

- Telltales like ABS, battery fault, and side stand may be **safety relevant** (ISO 26262 / ISO 13849 depending on the product). Use **Qt Safe Renderer** (`SafeImage`, `SafeText`) on a supported board (TRAVEO T2G) so they still show if the main UI freezes.
- Follow ISO 2575 symbols and colours, and the local regulations (India: CMVR / relevant BIS and ARAI standards for two-wheeler instrument clusters). Check with your homologation team.
- Hardware watchdog on the UI task; show a safe fallback (telltales + speed) if the UI restarts.

## Security

- BLE: LE Secure Connections bonding, allow-list bonded phones, reject unknown frame versions.
- Validate every length field (the parser does), never trust phone text lengths.
- Map tiles / files from SD card are untrusted input — check sizes and checksums.
- OTA (Over-The-Air) updates: signed images + A/B partitions + rollback.
- Anti-theft PIN: rate limit (3 tries), unlock from the app, store PIN hash in secure storage.

## Robustness

- EMC (Electromagnetic Compatibility): CAN common-mode choke, TVS diodes, shielded display cable.
- Temperature: −20 °C … +70 °C operation; LCD response is slow in the cold → avoid fast animations there.
- Brown-out: save odometer / trip only through the VCU (the cluster should not be the master copy).
- Vibration: secure connectors, conformal coating.

## Common mistakes to avoid

- Using desktop Qt Quick types (the build fails, run `qul_lint.py`).
- Updating properties from an ISR or another task (use `EventQueue`).
- Decoding in QML (do it in C++).
- Streaming the full phone screen over BLE (too slow — use turn-by-turn data).
- Big PNGs with full alpha everywhere (flash and blend cost).
