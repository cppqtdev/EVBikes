# 02 — Qul::Object and Qul::Singleton

Two classes, one decision: does your type exist **once**, or **many times**?

## Qul::Singleton — one of them, reachable by name

```cpp
#include <qul/singleton.h>

template <typename T> struct Qul::Singleton
```

> "Inherit from this class to expose the C++ class or struct to the QML as a
> singleton."

One static member function:

```cpp
static T& instance()
```

### When you reach for it

Almost always. Vehicle data, navigation state, system clock, user settings — a
cluster has exactly one of each. If you catch yourself asking "where do I get
the instance from", you wanted a singleton.

### The benefit

- QML reaches it by name with no wiring: `VehicleData.speedKmh`
- C++ reaches it the same way everywhere: `VehicleData::instance()`
- No ownership question, no pointer to pass around, no lifetime to manage —
  which on a system with no heap is worth a great deal

### Step by step

**1. Inherit, using your own type as the parameter.**

```cpp
struct VehicleData : public Qul::Singleton<VehicleData>
{
    Qul::Property<int> speedKmh;
};
```

That `VehicleData` appearing twice is not a typo. It is a standard C++ pattern
(the Curiously Recurring Template Pattern) that lets the base class know what
it is making a singleton *of*.

**2. List the header in `InterfaceFiles`.** Chapter 1, step 2.

**3. Read it in QML** — no import of the type, just the module:

```qml
import ClusterBackend

Text { text: VehicleData.speedKmh }
```

**4. Write it from C++:**

```cpp
VehicleData::instance().speedKmh.setValue(52);
```

### A detail worth copying

The docs suggest making the constructor private and declaring the base a
friend, so nobody can accidentally create a second one:

```cpp
struct VehicleData : public Qul::Singleton<VehicleData>
{
    Qul::Property<int> speedKmh;

private:
    VehicleData() = default;
    friend struct Qul::Singleton<VehicleData>;
};
```

Worth doing on a type that owns hardware state. For a plain data holder most
projects do not bother, and this project does not.

## Qul::Object — many of them, created in QML

```cpp
#include <qul/object.h>

class Qul::Object
```

> "Provides abstract implementation for all items or objects used in Qt Quick
> Ultralite."

It has no public API of its own. It is a marker: inherit from it and the
generator emits a QML type you can instantiate.

> "When a class inherits from Object and the header file is registered in
> QmlProject with the InterfaceFiles.files property then qmlinterfacegenerator
> will create a .qml file for it, which allows it to be used from QML."

It is exported to QML as a `QtObject`.

### When you reach for it

When the *same kind of thing* exists more than once and QML decides how many.
A per-channel controller, a per-item animator, a reusable helper that several
screens each want their own copy of.

```cpp
// BatteryCell.h
#pragma once

#include <qul/object.h>
#include <qul/property.h>

struct BatteryCell : public Qul::Object
{
    Qul::Property<int>  millivolts;
    Qul::Property<bool> balancing;
};
```

```qml
import ClusterBackend

Item {
    BatteryCell { id: cellA }
    BatteryCell { id: cellB }

    Text { text: cellA.millivolts }
}
```

### The honest caveat

On a system with no heap, "many instances" still means a number fixed at build
time — the objects QML declares, laid out statically. You cannot make more at
runtime. If the count is genuinely fixed and small, a few singletons or one
singleton holding an array is often simpler, and that is the road this project
took: ten singletons, no `Qul::Object` anywhere.

So: reach for `Qul::Object` when QML genuinely owns the instances. Otherwise
`Qul::Singleton` will serve you better.

## Choosing between them

| Question | Answer |
|---|---|
| Is there exactly one in the whole system? | `Singleton` |
| Does C++ own it and own its lifetime? | `Singleton` |
| Does QML decide where and how many? | `Object` |
| Do you need to pass it around as a pointer? | `Object` |
| Unsure? | `Singleton`. It is easier to split one later than to collect many. |

## From this project

Ten singletons, each one a subsystem:

```
VehicleData       speed, battery, telltale flags
ConnectivityData  bluetooth and phone link state
NavigationData    maneuver, distance, road name
PhoneData         call and message state
PhoneListData     contacts and reminders
SystemData        clock, temperature, units
TripData          odometer and trip counters
AlertData         which alert card is up
ClusterInput      button events from the handlebar
Simulator         the desktop demo driver
```

That split is the useful lesson, more than the API: **one singleton per
subsystem, named for what it holds.** A page reads the singletons it needs and
never talks to the bus. One boundary, and both sides can be tested on their
own.

## Traps

**You forget the header in `InterfaceFiles`** and QML reports the type does not
exist. Always the first thing to check.

**You put logic in the singleton that belongs in a decoder.** The singleton is
a place to *hold* state. Protocol parsing belongs in its own class that writes
into it — then you can unit test the parsing on your desktop without a board.

**You expect `Qul::Object` to give you runtime creation.** It does not. No
heap, no `createObject`.

## Check it yourself

```bash
grep -rn "Qul::Singleton<\|public Qul::Object" --include='*.h' .
```

Each hit should be a subsystem you can name in one word. If one of them is
called something like `Helpers` or `Misc`, it is probably two things.

## Sources

- [Qul::Singleton](https://doc.qt.io/QtForMCUs/qul-singleton.html)
- [Qul::Object](https://doc.qt.io/QtForMCUs/qul-object.html)
- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
