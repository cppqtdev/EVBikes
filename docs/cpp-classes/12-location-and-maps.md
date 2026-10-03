# 12 — Location and maps

Three classes feed the QtPositioning and QtLocation QML types. Both are marked
**experimental**, so read the version notes before you build a product on them.

## Qul::GeoPositionInfo — one fix

```cpp
#include <qul/geopositionsource.h>

struct Qul::GeoPositionInfo
```

```cpp
GeoPositionInfo(double latitude, double longitude, double direction,
                double speed, uint64_t timestamp = 0);

double   latitude;
double   longitude;
double   direction;
double   speed;        // since 2.12
uint64_t timestamp;    // since 2.12

bool hasLatitude() const;
bool hasLongitude() const;
bool hasDirection() const;
bool hasSpeed() const;      // since 2.12
```

A plain data carrier: one position fix, as it came off the GPS.

The `has...()` methods matter. A GPS with a weak lock gives you a position but
no heading; a stationary one gives you no meaningful speed. **Check before you
use**, or the compass needle will point north every time the signal dips.

## Qul::GeoPositionSource — where fixes come from

```cpp
#include <qul/geopositionsource.h>

class Qul::GeoPositionSource
```

> "Provides an abstract API to implement retrieving position information."

```cpp
virtual Qul::Private::PositionSource::SourceError
getCurrentPosition(Qul::GeoPositionInfo &positionInfo) = 0;
```

Experimental in Qt for MCUs 2.11 and later.

### Step by step

**1. Implement it:**

```cpp
#include <qul/geopositionsource.h>

struct GnssSource : public Qul::GeoPositionSource
{
    Qul::Private::PositionSource::SourceError
    getCurrentPosition(Qul::GeoPositionInfo &info) override
    {
        info = Qul::GeoPositionInfo(g_gnss.lat(), g_gnss.lon(),
                                    g_gnss.heading(), g_gnss.speed(),
                                    g_gnss.timestampMs());
        return /* the no-error value of SourceError */;
    }
};
```

**The error values are deliberately not spelled out above.** The reference page
gives the return type as
`Qul::Private::PositionSource::SourceError` and says the method "returns one of
sourceError enum values", but it **does not name any of them**. Read the real
values out of your own installation before you write this:

```bash
grep -rn "SourceError" ~/QtForMCU/QtMCUs/*/include/ | head
```

Guessing an enumerator is how you turn a ten-minute job into a failed build.

**2. Register it, keeping it alive:**

```cpp
static GnssSource g_gnssSource;
Qul::Application::registerGeoPositionSource(&g_gnssSource);
```

**3. Consume it in QML** through QtPositioning's `PositionSource`:

```qml
import QtPositioning

PositionSource {
    id: gps
    active: true
}

Text { text: gps.position.coordinate.latitude }
```

Note the shape: the engine **pulls** from you. You do not push fixes in. Your
job is to answer "where are we right now" quickly, from whatever your GNSS
driver last parsed — not to block on the serial port inside this call.

## Qul::MapTileFetcher — where map tiles come from

```cpp
#include <qul/maptilefetcher.h>

class Qul::MapTileFetcher
```

> "Provides an abstract API to implement fetching of a map tile image."

```cpp
virtual bool getTileImage(const Qul::Private::TileSpec &spec,
                          Qul::Private::TileImage &tileImage) = 0;
```

Experimental since Qt Quick Ultralite 2.10.

```cpp
static TileFetcher g_tiles;
Qul::Application::addMapTileFetcher(&g_tiles);
```

Consumed by the `Map` item in QtLocation. You receive a tile specification —
which tile, at what zoom — and store a `SharedImage` into `tileImage`,
returning `true` if you managed it.

Where the tile comes from is entirely yours: flash for an offline region, an
SD card, the phone over Bluetooth, a decoded download.

### Think about the budget before you start

A map is the most expensive thing an MCU cluster can draw. Each tile is
typically 256×256; at 4 bytes per pixel that is **256 KB decoded, per tile**.
A 1280×480 screen wants fifteen or more of them to cover it.

Before implementing this, work out:

- how many tiles are on screen at once
- how many you cache, and where that memory comes from
- what happens when `getTileImage` cannot deliver in time

This project draws its navigation view as **pre-rendered turn arrows and route
images**, not as live map tiles, precisely because that arithmetic did not
work. A turn arrow is a few KB; a tiled map is megabytes. If your navigation
needs are "which way do I turn", pre-rendered art is both cheaper and clearer.

## Traps

**Your source or fetcher is not static.** The application does not take
ownership. A dangling pointer that works until the stack is reused.

**You ignore the `has...()` checks.** A fix without heading is normal, not
exceptional.

**You block inside `getCurrentPosition`.** It is called on the main loop.
Reading a UART there costs you frames. Parse in your driver, answer from a
cached value.

**You build on experimental API without noting the version.** Both are
experimental; the GeoPositionInfo `speed` and `timestamp` fields only exist
from 2.12.

**You underestimate tile memory.** Do the multiplication first.

## Check it yourself

```bash
grep -rn "registerGeoPositionSource\|addMapTileFetcher" --include='*.cpp' .
```

Both arguments should point at objects with static storage duration.

## Sources

- [Qul::GeoPositionInfo](https://doc.qt.io/QtForMCUs/qul-geopositioninfo.html)
- [Qul::GeoPositionSource](https://doc.qt.io/QtForMCUs/qul-geopositionsource.html)
- [Qul::MapTileFetcher](https://doc.qt.io/QtForMCUs/qul-maptilefetcher.html)
