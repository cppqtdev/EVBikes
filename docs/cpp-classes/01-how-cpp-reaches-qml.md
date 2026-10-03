# 01 — How C++ reaches QML

Before any individual class makes sense, you need the mechanism. It is small,
and once you have seen it you will know where every other class plugs in.

## The problem it solves

Your QML draws a speedometer. The actual speed comes from a CAN bus, decoded in
C++. Something has to carry the number from one to the other, and it has to do
it without a heap, without a parser, and fast enough to not cost you a frame.

On desktop Qt this is `Q_OBJECT`, `Q_PROPERTY`, moc, `qmlRegisterType` and a
`QVariant` round trip. Qt for MCUs throws all of that away.

## What replaces it

You write a plain C++ struct. You list its header in the `.qmlproject`. A build
tool called **`qmlinterfacegenerator`** reads that header and writes the QML
type for you. There is no registration call anywhere in your code.

That is the whole mechanism. Three steps.

### Step 1 — write a plain struct

```cpp
// VehicleData.h
#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

struct VehicleData : public Qul::Singleton<VehicleData>
{
    Qul::Property<int>  speedKmh;
    Qul::Property<bool> absFault;
};
```

No `Q_OBJECT`. No macros at all. Two things make it visible to QML:

- it **inherits** `Qul::Singleton<VehicleData>`, which says "one global instance,
  reachable by name from QML"
- its **public members** are `Qul::Property<T>`, which is what a QML binding can
  read and react to

### Step 2 — list the header in the `.qmlproject`

```qml
// backend.qmlproject                              from this project
import QmlProject 1.3

Project {
    MCU.Module {
        uri: "ClusterBackend"
    }

    InterfaceFiles {
        files: [
            "VehicleData.h",
            "NavigationData.h",
            "ClusterInput.h",
            "Simulator.h"
        ]
    }
}
```

`InterfaceFiles` is the list `qmlinterfacegenerator` reads. A header that is not
in this list is invisible to QML, however correct it looks. This is the single
most common reason a new backend type "does not exist" in QML.

`MCU.Module { uri: "ClusterBackend" }` names the module. That is the name you
import in QML.

### Step 3 — use it in QML

```qml
import ClusterBackend

Text {
    text: VehicleData.speedKmh + " km/h"
    color: VehicleData.absFault ? "red" : "white"
}
```

No import of a specific type, no instantiation. The singleton is simply there.

And from C++, the other direction:

```cpp
VehicleData::instance().speedKmh.setValue(52);
```

The `Text` updates. You did not call anything on the UI.

## What the generator actually produces

```
VehicleData.h  ──►  qmlinterfacegenerator  ──►  VehicleData.qml  (generated)
                                                 pragma Singleton
                                                 QtObject {
                                                     property int speedKmh
                                                     property bool absFault
                                                 }
```

A generated `.qml` shim with `pragma Singleton`, matching your struct field for
field. `qmltocpp` then compiles that shim along with the rest of your QML. By
the time the binary is linked, the connection between `speedKmh` the C++ member
and `speedKmh` the QML property is direct — no lookup by name at runtime.

This is why there is no heap cost and no registration call. It all happened at
build time.

## The four building blocks

Almost everything you expose is made of four things. The rest of this guide is
mostly detail about them.

| You want | Use | Chapter |
|---|---|---|
| A value QML can read and bind to | `Qul::Property<T>` | 3 |
| One global object, reachable by name | `Qul::Singleton<T>` | 2 |
| Many instances, created in QML | `Qul::Object` | 2 |
| To tell QML "this just happened" | `Qul::Signal<T>` | 4 |

A real backend type is usually a singleton holding a handful of properties and
maybe one signal. Here is one from this project, complete:

```cpp
// ClusterInput.h                                  from this project
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

Note the enums: those come across to QML too, as `ClusterInput.Ok`,
`ClusterInput.LongPress`. You get named constants on both sides from one
declaration.

## The direction of travel matters

This trips up people coming from desktop Qt, so it is worth being blunt:

**C++ pushes values in. QML pulls them out through bindings.**

You do not call a QML function from C++ to update the screen. You set a
property, and every binding that reads it re-evaluates. If you find yourself
wanting to reach into QML and change something, the answer is almost always a
property you have not declared yet.

The one exception is a signal, for things that are events rather than states —
a button press, a message arriving. That is chapter 4.

## Traps

**The header is not in `InterfaceFiles`.** QML says the type does not exist.
Nothing else is wrong. Check this first, every time.

**You expose a function and expect to call it from QML.** Plain member
functions are not exposed. QML reads properties and connects to signals. Give
the thing a property, or drive it from a signal handler in C++.

**You use a narrow integer type and the numbers come out wrong.** QML has one
integer type. Mirroring a `uint16_t` across the boundary corrupted every number
on screen in this project; 8-bit and 32-bit survived. Widen at the boundary —
exactly what the comment in `ClusterInput.h` above is about.

**You expect a value to be readable back from QML into C++.** It is one way.
C++ owns the value; QML displays it.

## Check it yourself

List what your project exposes, and confirm each header is actually declared:

```bash
grep -rl "Qul::Singleton\|Qul::Object" --include='*.h' .
grep -A20 "InterfaceFiles" */*.qmlproject
```

Anything in the first list and missing from the second is invisible to QML.

## Sources

- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
- [Qul namespace](https://doc.qt.io/QtForMCUs/qul.html)
- [InterfaceFiles](https://doc.qt.io/QtForMCUs/qtul-qmlproject-interfacefiles.html)
