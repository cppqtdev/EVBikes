# 05 — The C++ bridge

This part of Qt for MCUs is genuinely good. The bridge is small, typed, and
generated — no `Q_OBJECT`, no moc, no `qmlRegisterType`, no `QVariant`.

## The shape

```cpp
// qml/backend/VehicleData.h
#pragma once
#include <qul/singleton.h>
#include <qul/property.h>

struct VehicleData : public Qul::Singleton<VehicleData>
{
    enum RideMode { Eco, City, Sport };

    Qul::Property<int>      speedKmh;
    Qul::Property<uint8_t>  batteryPercent;
    Qul::Property<bool>     absFault;
    Qul::Property<uint16_t> telltaleFlags;
};
```

List the header in the module's `.qmlproject`:

```qml
MCU.Module { uri: "ClusterBackend" }
InterfaceFiles { files: ["qml/backend/VehicleData.h"] }
```

and use it:

```qml
import ClusterBackend

Text { text: "" + VehicleData.speedKmh }
Telltale { active: VehicleData.absFault }
```

`qmlinterfacegenerator` reads the header, writes a QML shim, and `qmltocpp`
compiles against it. No registration call anywhere.

## The building blocks

| Class | Header | For |
|---|---|---|
| `Qul::Object` | `qul/object.h` | The base everything exposed derives from |
| `Qul::Singleton<T>` | `qul/singleton.h` | One global instance, `pragma Singleton` applied for you |
| `Qul::Property<T>` | `qul/property.h` | A bindable property |
| `Qul::Signal<Fn>` | `qul/signal.h` | A signal QML can connect to |
| `Qul::ListProperty<T>` | | A list of a type |
| `Qul::ListModel<T>` | | A full model to expose |
| `Qul::EventQueue<T>` | `qul/eventqueue.h` | Cross-thread and ISR to UI |
| `Qul::Timer` | `qul/timer.h` | Repeating and single-shot timers |
| `Qul::Application` | `qul/application.h` | Starts the engine |
| `Qul::ApplicationConfiguration` | `qul/application.h` | Text cache settings, passed to the `Application` constructor |
| `Qul::Image`, `Qul::SharedImage` | | Direct pixel access |
| `Qul::ImageProvider` | | Serve images to QML from C++ |
| `Qul::PlatformInterface` | | The platform porting layer |

Two rules the generator enforces:

- the class must derive from `Qul::Object` (directly or through `Singleton`)
- it must be default-constructible

## Type mapping

| C++ | QML |
|---|---|
| `bool` | `bool` |
| any integer type | `int` |
| `float`, `double` | `real` |
| `std::string` | `string` |
| a public `enum` | a QML enum — `VehicleData.Sport` |
| `T*` where `T : Qul::Object` | the matching component type |
| `Qul::ListProperty<T>` | `list` |

### The narrowing trap

**QML has exactly one integer type.** A `Qul::Property<uint16_t>` is an `int`
in QML. That is fine going out — but if you mirror these into a desktop shim
and keep the narrow type, you get corruption that looks like nonsense.

In this project every numeric readout showed garbage on the desktop build.
The cause was the generated bridge mirroring the backend's narrow types into
the Qt `Q_PROPERTY` declarations: 8-bit and 32-bit survived, 16-bit did not.
The fix was in the generator's type map:

```python
TYPE_MAP = {
    "bool": "bool", "float": "double", "double": "double",
    "int": "int", "int8_t": "int", "uint8_t": "int",
    "int16_t": "int", "uint16_t": "int",      # widen at the boundary
    "int32_t": "int", "uint32_t": "int",
    "std::string": "QString",
}
```

> **The rule:** narrow types are for the wire and for storage. Widen at the QML
> boundary and keep them widened.

## Signals

```cpp
struct ClusterInput : public Qul::Singleton<ClusterInput>
{
    Qul::Signal<void(int button, int action)> buttonEvent;
    void inject(int b, int a) { buttonEvent(b, a); }
};
```

```qml
Connections {
    target: ClusterInput
    function onButtonEvent(button: int, action: int) { Router.handleButton(button, action) }
}
```

The template argument is a function type carrying **parameter names**, and QML
uses those names. One sharp edge:

> Do not mix `function onFoo(...)` with the older `onFoo:` form in the same
> `Connections` block. Ultralite then ignores the function handlers, silently.

## Grouped properties

```cpp
struct Theme : public Qul::Singleton<Theme>
{
    struct Colours { Qul::Property<int> accent; Qul::Property<int> warn; };
    Colours colours;     // Theme.colours.accent in QML
};
```

The grouping struct must **not** derive from `Qul::Object`.

## Crossing a thread or an interrupt

`setValue()` from an ISR or another thread is not safe and does not wake the
engine. `Qul::EventQueue` is the only supported route:

```cpp
static Qul::EventQueue<CanFrame> &canQueue()
{
    static struct Q : Qul::EventQueue<CanFrame> {
        void onEvent(const CanFrame &f) override { decode(f); }
    } q;
    return q;
}

void receiveCanFrameFromIsr(const CanFrame &f) { canQueue().postEventFromInterrupt(f); }
```

`onEvent` runs on the UI thread. `postEvent` from a thread,
`postEventFromInterrupt` from an ISR.

### The queue has a fixed size, and it drops

This cost a day. The simulator posted **eight** CAN frames per tick into a
queue that held **five**. Three were silently dropped every tick, and the
symptom was values that updated erratically with no error anywhere.

The desktop shim hid it completely: it delivers events synchronously, so
nothing ever overflows.

Fix, once the trace showed it:

```cpp
// Same-thread callers decode directly. The queue is for the ISR, which is
// the only caller that cannot.
void postCanFrame(const CanFrame &f) { decode(f); }
void postCanFrameFromIsr(const CanFrame &f) { canQueue().postEventFromInterrupt(f); }
```

> **The rule:** the queue is for crossing a boundary, not for ordinary calls.
> If you are already on the UI thread, call the function.

## QML-side singletons

For pure-QML shared state — a theme, a router, formatting helpers — use a QML
singleton inside a module:

```qml
// qml/core/Theme.qml
pragma Singleton
import QtQuick
QtObject {
    readonly property color accent: "#4FD9B2"
    readonly property font  bigFont: Qt.font({ family: "Inter", pixelSize: 32 })
}
```

`readonly` matters here beyond style: a readonly property is a configuration
the font engine can resolve at compile time (chapter 3), and it cannot be
accidentally assigned into a loop (chapter 4).

## Layering that holds up

What worked in this project:

```
QML pages ──► QML singletons (Theme, Router, Format)
          └─► C++ singletons (VehicleData, SystemData, …)
                     ▲
          decoders ──┘        ◄── EventQueue ◄── ISR / CAN / BLE
```

- **Pages never touch CAN or BLE.** Pages read singletons. Full stop.
- Decoders are plain C++ with no Qul dependency, so they unit-test on the host.
- Every new decode function gets a host test. They are cheap and they catch
  the bit-packing errors that are miserable to find on a board.

## Check it yourself

What the generator produced from your headers:

```
find build -name "*.qml" -path "*interface*" | head
```

Your queue sizes, against what you actually post per tick:

```
grep -rn "EventQueue<" src/ | head
```

## Sources

- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
- [Qul namespace](https://doc.qt.io/QtForMCUs/qul.html)
- [Qul::EventQueue](https://doc.qt.io/QtForMCUs/qul-eventqueue.html)
