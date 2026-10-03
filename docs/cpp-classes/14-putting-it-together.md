# 14 — Putting it together

A complete backend from nothing, in the order you would actually build it.
The goal: a speed readout on screen, fed by a CAN bus, with a button that
switches the view.

## Step 1 — the data type

Start with what the UI needs to know, not with the bus.

```cpp
// VehicleData.h
#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>

struct VehicleData : public Qul::Singleton<VehicleData>
{
    enum RideMode : uint8_t { Eco = 0, City, Sport };

    Qul::Property<uint16_t> speedKmh;
    Qul::Property<uint8_t>  batteryPercent;
    Qul::Property<uint8_t>  rideMode;
    Qul::Property<bool>     absFault;
    Qul::Property<uint32_t> telltaleFlags;
};
```

Decisions already made here:

- **A singleton**, because there is one vehicle
- **Units in the names** — `speedKmh`, not `speed`
- **An enum beside the property that uses it**, so QML writes
  `VehicleData.Sport`
- **One `telltaleFlags` bitfield** rather than sixteen booleans — one value
  for the engine to track, not sixteen

## Step 2 — the input type

Events, not state, so a signal.

```cpp
// ClusterInput.h
#pragma once

#include <qul/signal.h>
#include <qul/singleton.h>

#include <cstdint>

struct ClusterInput : public Qul::Singleton<ClusterInput>
{
    enum Button : uint8_t { Up = 0, Down, Left, Right, Ok, Mode, Back };
    enum Action : uint8_t { Press = 0, LongPress };

    // QML signal slots use its canonical int type; the hardware API stays byte-sized.
    Qul::Signal<void(int button, int action)> buttonEvent;

    void inject(uint8_t button, uint8_t action);
};
```

`inject()` is the seam: the GPIO driver calls it on hardware, the keyboard
calls it on desktop, and QML cannot tell.

## Step 3 — declare both to the generator

```qml
// backend.qmlproject
import QmlProject 1.3

Project {
    MCU.Module {
        uri: "ClusterBackend"
    }

    InterfaceFiles {
        files: [ "VehicleData.h", "ClusterInput.h" ]
    }
}
```

Miss this and QML reports the types do not exist. It is the first thing to
check, always.

## Step 4 — the bus, behind a queue

The interrupt must not touch the UI, so it posts and returns.

```cpp
// Backend.cpp
#include <qul/eventqueue.h>

struct CanFrame { uint32_t id; uint8_t len; uint8_t data[8]; };   // POD

class CanQueue : public Qul::EventQueue<CanFrame,
                                        Qul::EventQueueOverrunPolicy_Discard,
                                        16>
{
public:
    void onEvent(const CanFrame &frame) override
    {
        g_decoder.decode(frame);      // main loop: safe to write properties
    }

    void onQueueOverrun() override { ++g_canOverruns; }
};

CanQueue &canQueue() { static CanQueue q; return q; }
```

Sixteen, not the default five, because the bus can deliver more than five
frames between two frames of UI. And `onQueueOverrun` is overridden, so a
drop is a number you can see rather than data that is quietly wrong.

```cpp
extern "C" void CAN0_IRQHandler()
{
    canQueue().postEventFromInterrupt(readFrame());
}
```

## Step 5 — the decoder, testable on your desktop

Keep protocol knowledge in its own class. It writes into the singleton and
knows nothing about QML.

```cpp
void Decoder::decode(const CanFrame &f)
{
    switch (f.id) {
    case 0x101:
        VehicleData::instance().speedKmh.setValue((f.data[0] << 8) | f.data[1]);
        break;
    case 0x102:
        VehicleData::instance().batteryPercent.setValue(f.data[0]);
        break;
    }
}
```

This function is a pure transformation from bytes to properties, so you can
unit test it on a host with no board and no display. Bit packing is miserable
to debug on hardware and trivial to test off it.

## Step 6 — a timer for what has no interrupt

```cpp
// Backend.cpp
static Qul::Timer g_pollTimer;
static uint32_t   g_lastMs = 0;

void Backend::startRuntime()
{
    g_lastMs = platform::millis();
    g_pollTimer.onTimeout([] {
        const uint32_t now     = platform::millis();
        const uint32_t gap     = now - g_lastMs;
        const uint32_t elapsed = gap > 100 ? 100 : gap;   // clamp
        g_lastMs = now;

        pollTemperature(elapsed);
        checkNodeTimeouts(now);
    });
    g_pollTimer.setInterval(16);
    g_pollTimer.start();
}
```

The clamp matters. The first tick after startup is always long.

## Step 7 — main()

```cpp
#include "Main.h"                 // generated from Main.qml
#include "backend/Backend.h"

#include <qul/application.h>
#include <qul/qul.h>

int main()
{
    Qul::initHardware();
    Qul::initPlatform();
    Backend::init();

    Qul::ApplicationConfiguration config;
    config.setTextCacheSize(96 * 1024);     // 96 KB of VRAM back
    Qul::Application app(config);

    static struct ::Main item;
    app.setRootItem(&item);

    Backend::startRuntime();
    app.exec();
    Backend::stopRuntime();
    return 0;
}
```

## Step 8 — the QML side

```qml
import QtQuick
import ClusterBackend

Item {
    width: 1280
    height: 480

    Text {
        text: VehicleData.speedKmh
        color: VehicleData.absFault ? "#F02A3C" : "#FFFFFF"
        font.pixelSize: 124
    }

    Text {
        text: VehicleData.rideMode === VehicleData.Sport ? "SPORT"
            : VehicleData.rideMode === VehicleData.City  ? "CITY"
            : "ECO"
    }

    Connections {
        target: ClusterInput
        onButtonEvent: {
            if (button === ClusterInput.Mode && action === ClusterInput.Press)
                Router.nextView()
        }
    }
}
```

That is the whole loop: interrupt → queue → decoder → property → binding →
pixels, and button → signal → handler → router.

## The shape to keep

```
  interrupt / thread
          │  postEventFromInterrupt()
          ▼
    Qul::EventQueue          fixed size, overrun counted
          │  onEvent()  — main loop from here down
          ▼
      your decoder           no Qt types; unit tested on a host
          │  setValue()
          ▼
    Qul::Singleton           properties only; no protocol knowledge
          │  binding
          ▼
         QML                 reads singletons; never touches the bus
```

Four layers, each testable on its own. **Pages never touch the bus; decoders
never touch QML.** That one rule is worth more than any individual class in
this guide.

## "I want to…" — the lookup table

| I want to | Use | Chapter |
|---|---|---|
| Show a C++ value on screen | `Qul::Property` in a `Qul::Singleton` | 2, 3 |
| Tell QML something happened | `Qul::Signal` | 4 |
| Have several instances QML creates | `Qul::Object` | 2 |
| Feed a `Repeater` or `ListView` | `Qul::ListModel`, or a constant model plus `visible` | 5 |
| Expose a list of child objects | `Qul::ListProperty` | 5 |
| Get data in from an interrupt | `Qul::EventQueue` | 6 |
| Do something every N ms | `Qul::Timer` | 7 |
| Start the engine | `Qul::Application` | 8 |
| Shrink the 192 KB text cache | `Qul::ApplicationConfiguration` | 8 |
| Change the UI language | `Qul::ApplicationSettings` | 8 |
| Show pixels I produced | `Qul::Image` + `Qul::ImageProvider` | 9 |
| Edit pixels while they are on screen | `Qul::ImageWriteGuard` | 9 |
| Draw something procedurally | `Qul::PaintedItemDelegate` | 9 |
| Read a blob I shipped in flash | `Qul::BinaryResource` | 10 |
| Read from an SD card | implement `Filesystem` and `File` | 10, 13 |
| Decode an image at runtime | implement `ImageDecoder` | 10, 13 |
| Accept any string type in a function | `Qul::String` | 11 |
| Return success-or-error | `Qul::Status` (2.10+) | 11 |
| Hold a type-safe bitmask | `Qul::Flags` (2.12+) | 11 |
| Feed GPS | `Qul::GeoPositionSource` | 12 |
| Feed map tiles | `Qul::MapTileFetcher` | 12 |
| Port to a new board | `Qul::Platform::PlatformContext` | 13 |

## The eight habits

1. **One singleton per subsystem**, named for what it holds.
2. **Units in property names.** `distanceToManeuverM`, `etaMinutes`.
3. **Enums next to the properties that use them**, so QML never writes a bare
   number.
4. **Widen to `int` at the QML boundary.** Narrow inside your own code.
5. **Size every `EventQueue` from your real data rate** and override
   `onQueueOverrun`.
6. **Clamp elapsed time** in every timer callback.
7. **Decoders never touch QML; pages never touch the bus.**
8. **Verify the header before you include it.** An invented include name stops
   the build, and guessing has cost this project a round already.

## Sources

- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
- [Qul namespace](https://doc.qt.io/QtForMCUs/qul.html)
- [C++ Classes and Namespaces](https://doc.qt.io/QtForMCUs/qtul-cppclasses.html)
