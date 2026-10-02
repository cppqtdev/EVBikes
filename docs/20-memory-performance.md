# Memory, executable size and renderer measurements

## Implemented

- Bottom-left transparent diagnostics: actual QUL renderer FPS, sampled minimum/mean, repaint percentage and approximate frame interval (1000/FPS). F12 toggles diagnostics. No new polling timer.
- Heap/stack peaks use platform performance metrics. Unsupported values display `n/a`; simulator CPU is also `n/a`. These are not total RAM usage.
- Cropped four battery images to their alpha bounds, retaining their original screen positions. Estimated decoded Alpha8 saving: 2,130,158 bytes (2.03 MiB).
- Referenced PNG decoded budget decreased from 15,776,456 to 13,646,298 bytes. This is an asset estimate, not measured peak residency.
- Desktop resource cache limit reduced from 21 to 16 MiB per configured allocation type. Limits are not allocations or measured savings. TRAVEO uses its separate external-flash/NoCaching profile.
- Reduced unnecessary number-readout digit delegates by 16 across component declarations; instantiated savings depend on the current screen.
- Qt6 fallback packages only referenced PNGs and fonts.
- GCC Release uses size optimization, function/data sections and linker garbage collection. `EVBikes-package` strips a separate distribution copy and preserves the original executable.
- Removed the optional 8,556,899-byte `assets/source/bike.png`. Existing small bike runtime PNGs remain. The artwork generator retains these when the optional source is absent. That large source was never packaged into the executable.

## Measured desktop baseline

The original Debug executable was 39,970,320 bytes. Optimized Release was approximately 4.85 MiB; the stripped executable approximately 3.78 MiB. These are executable sizes, excluding shared Qt/system libraries, and are not MCU firmware or RAM measurements. Removing debug symbols does not save equivalent runtime RAM.

One simulator capture showed 59.9 FPS, sampled minimum 59.1, sampled mean 59.3 and repaint 0.5%. This is a sample, not a worst-case guarantee. FPS comes from the renderer, not simulator ticks or display refresh. Repaint is a percentage, not milliseconds. Heap/stack are unavailable on the current desktop platform. Profiling has overhead; disable it when comparing production performance.

## Remaining improvement checklist

| Area | Next action / tradeoff |
| --- | --- |
| Images | Audit decoded dimensions and alpha bounds; remove unreferenced resources and duplicate resolutions. PNG file compression alone does not reduce decoded RAM. |
| Formats | Use Alpha8 for tinted monochrome art; use RGB565 for opaque art where quality permits. Retain alpha only where required. Compare board-supported compression and bandwidth. |
| Fonts | Restrict glyph ranges to supported languages and reuse font sizes/styles. Preserve characters required by road names. |
| Rendering | Profile overdraw, translucent glows, gradients, clipping, large dirty areas and continuous gauge paths; simplify only expensive measured operations. |
| Animation | Stop hidden animations; update slow-changing navigation/status at lower rates while keeping speed/needle responsive. Publish only changed values. |
| Screens | Retain lazy loading; consider optional builds with one gauge style or without map/diagnostics. Do not remove user-visible features silently. |
| Backend | Keep bounded CAN queues, fixed-size storage and explicit overflow/stale handling. Avoid allocations or UI work in interrupt handlers. Use signed types for negative temperatures and adequate counters for distance/time. |
| Build | Inspect linker map and symbol sizes. Evaluate LTO with the target SDK before enabling it. Keep symbols separately; exclude simulator/logging from hardware production builds. |
| Memory | Measure heap/stack high-water marks, resource cache, glyph cache, framebuffer and driver allocations separately. Run long-duration screen-switch/CAN-load checks before claiming no leaks. |
| Hardware | Measure external-flash bandwidth, drawing-engine behavior, layer formats and framebuffer placement on CYT4DN. Desktop measurements cannot establish hardware limits. |

## Framebuffer budget at 1280 × 480

| Pixel format | One full buffer | Two full buffers |
| --- | ---: | ---: |
| 16 bpp | 1.172 MiB | 2.344 MiB |
| 24 bpp | 1.758 MiB | 3.516 MiB |
| 32 bpp | 2.344 MiB | 4.688 MiB |

These exclude alignment, layers, caches, stack and heap. Two full 32-bit buffers exceed 4 MiB by themselves. Use the TRAVEO port's supported layer/on-the-fly configuration and measure its actual line buffers; changing application color depth alone is not a complete framebuffer plan.

## Commands

```sh
python3 tools/trim_battery_assets.py
python3 tools/sync_project_files.py
python3 tools/audit_assets.py
cmake --build build/Qt_for_MCUs_2_12_Desktop_32bpp_GCC_Release --target EVBikes-package --parallel 4
```

After regenerating original artwork, rerun trimming and project synchronization. Distribution executable: `build/Qt_for_MCUs_2_12_Desktop_32bpp_GCC_Release/package/EVBikes`.

References: [Qt performance logging](https://doc.qt.io/QtForMCUs/qtul-performance-logging.html), [QulPerf](https://doc.qt.io/QtForMCUs/qml-qtquickultralite-extras-qulperf.html), [TRAVEO layer/VRAM guide](https://doc.qt.io/QtForMCUs/qtul-t2g-layer-vram-guide.html). Profiling support depends on the platform and library build.
