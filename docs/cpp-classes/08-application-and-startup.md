# 08 — Application and startup

Four classes own the beginning and end of your program: `Application`,
`ApplicationConfiguration`, `ApplicationSettings` and `RootItem`.

## Qul::Application

```cpp
#include <qul/application.h>

class Qul::Application
```

> "The Application class is used to start Qt Quick Ultralite."

```cpp
Application();
Application(const Qul::ApplicationConfiguration &applicationConfigs);

void setRootItem(Qul::RootItem *root);
void exec();
uint64_t update();                           // since 1.8, for a custom main loop

Qul::ApplicationSettings &settings();
const Qul::ApplicationSettings &settings() const;

static void addFilesystem(Qul::PlatformInterface::Filesystem *filesystem);
static void addImageDecoder(Qul::PlatformInterface::ImageDecoder *imagedecoder);
static void addImageProvider(const char *providerId, Qul::ImageProvider *provider);
static void addMapTileFetcher(Qul::MapTileFetcher *tilefetcher);
static void registerGeoPositionSource(Qul::GeoPositionSource *positionSource);
```

Those five statics are the extension points: file access, image decoding,
image providers, map tiles, GPS. Each is covered in its own chapter.

> The Application "does not take ownership" of any of those objects. Keep them
> alive yourself — in practice, make them file-scope statics.

## Qul::RootItem

```cpp
#include <qul/rootitem.h>

class Qul::RootItem
```

> "RootItem is a base class of items defined in QML files. It has no public
> API, it is only the type that Application::setRootItem() accepts a pointer
> to."

You never write one. `qmltocpp` generates a C++ class from your root `.qml`,
and a pointer to it converts to `RootItem *`. That is the one thing you need to
know:

```cpp
#include "Main.h"            // generated from Main.qml

static struct ::Main item;
app.setRootItem(&item);
```

Note `static`. The root item must outlive `exec()`, and on a system with no
heap, static storage is where it lives.

## The startup sequence

The order is not negotiable.

```cpp
// src/main.cpp                                   from this project
#include "Main.h"
#include "backend/Backend.h"

#include <qul/application.h>
#include <qul/qul.h>

int main()
{
    Qul::initHardware();          // 1. clocks, pins, peripherals
    Qul::initPlatform();          // 2. display, framebuffer, input
    Backend::init();              // 3. your own setup

    Qul::Application app;         // 4. the engine
    static struct ::Main item;    // 5. the root item, statically
    app.setRootItem(&item);       // 6. hand it over

    Backend::startRuntime();      // 7. your timers and queues
    app.exec();                   // 8. never returns, normally
    Backend::stopRuntime();
    return 0;
}
```

**Why this order:**

1. `initHardware()` — the board itself. Nothing works before it.
2. `initPlatform()` — the Qt platform port: display, framebuffer, touch.
3. Your backend — decoders, queues, initial property values.
4. `Application` — constructing it initialises Qt Quick Ultralite.
5. and 6. The root item must exist before `exec()` has anything to draw.
7. Start your timers after the engine exists, so their callbacks are safe.
8. `exec()` runs the frame loop forever.

If you get a blank screen at startup, walk this list. In this project a boot
trace was added that prints before each step, because **the last line printed
names the call that did not return**:

```cpp
#define EVB_TRACE(msg) do { std::printf("[boot] " msg "\n"); std::fflush(stdout); } while (0)
```

Crude, and it has paid for itself several times.

## Qul::ApplicationConfiguration

```cpp
#include <qul/application.h>     // same header, not one of its own

class Qul::ApplicationConfiguration
```

> "The Application configuration class with text cache and other
> configurations."

```cpp
void setTextCacheEnabled(bool value);     // since 2.1
void setTextCacheSize(int size);          // since 2.1
bool textCacheEnabled() const;            // since 2.1
int  textCacheSize() const;               // since 2.1
```

It is **passed to the constructor**, not set statically:

```cpp
Qul::ApplicationConfiguration config;
config.setTextCacheSize(96 * 1024);
Qul::Application app(config);
```

### Why you care

The text cache defaults to **192 KB of VRAM**. With the static font engine the
glyphs already live in flash, so the cache only holds text that changes. On a
cluster that is a handful of readouts, and the default is usually generous.

Cutting it to 96 KB gives you 96 KB of VRAM back, which on a board where VRAM
is the tight resource is a real win.

> A warning from experience: this header is `qul/application.h`. There is no
> `qul/applicationconfiguration.h` — inventing that name in this project stopped
> the build outright. The class has existed since Qt Quick Ultralite **2.1**.

## Qul::ApplicationSettings

```cpp
#include <qul/applicationsettings.h>

class Qul::ApplicationSettings      // since 2.0
```

> "The ApplicationSettings class is a container for `Application` settings."

You get it from the application, and the one documented property is the UI
language:

```cpp
Qul::Application app;
app.settings().uiLanguage.setValue("pl_PL");
```

That reflects `Qt.uiLanguage` in QML and defaults to an empty string. If you
ship more than one language, this is the switch.

## A custom main loop

`exec()` runs the loop for you. If you need to own it — because an RTOS task
or another framework owns the loop instead — use `update()`:

```cpp
for (;;) {
    uint64_t nextDue = app.update();
    doMyOwnWork();
    sleepUntil(nextDue);
}
```

`update()` has been there since 1.8. Most projects should use `exec()`; reach
for this only when something else genuinely must own the loop.

## Traps

**You put the root item on the stack.** `Main item;` inside `main()` happens to
work because `main()` never returns, but it puts a large object on the stack,
which on an MCU is the scarcest memory you have. Make it `static`.

**You call `initPlatform()` before `initHardware()`.** The display comes up
before its clock does. Usually a hang with no output.

**You start timers before the `Application` exists.** A callback can fire into
an engine that is not there yet.

**You invent a header name.** See the warning above. Check the real header
before you include it.

**You let an image provider or filesystem go out of scope.** The application
does not own them.

## Check it yourself

```bash
grep -n "initHardware\|initPlatform\|Qul::Application\|setRootItem\|exec()" src/main.cpp
```

They should appear in that order, and the root item should be `static`.

## Sources

- [Qul::Application](https://doc.qt.io/QtForMCUs/qul-application.html)
- [Qul::ApplicationConfiguration](https://doc.qt.io/QtForMCUs/qul-applicationconfiguration.html)
- [Qul::ApplicationSettings](https://doc.qt.io/QtForMCUs/qul-applicationsettings.html)
- [Qul::RootItem](https://doc.qt.io/QtForMCUs/qul-rootitem.html)
