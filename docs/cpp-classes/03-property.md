# 03 — Qul::Property

The one you will use most. In this project it appears 131 times; everything
else combined appears twelve.

```cpp
#include <qul/property.h>

template <typename T> struct Qul::Property
```

> "The Property class can be used to hold a property of a given type."

## The complete API

That is not a joke — this is all of it:

```cpp
Property()                        // zero-initialised
explicit Property(const T &value) // initialised
void setValue(const T &v)
const T &value()
const T &value() const
```

Five functions. Everything else is the engine's job.

## What it actually does for you

A plain `int` member is just a number; nothing notices when it changes. A
`Qul::Property<int>` is a number **that the engine watches**. When you call
`setValue`, every QML binding that reads it is marked dirty and re-evaluated
before the next frame.

```cpp
VehicleData::instance().speedKmh.setValue(52);
```

```qml
Text { text: VehicleData.speedKmh + " km/h" }   // now says 52 km/h
Rectangle { width: VehicleData.speedKmh * 2 }   // and this grew too
```

You wrote one line and did not mention either of those elements. **That is the
benefit**: the UI describes what it wants, C++ states what is true, and neither
knows about the other.

## Step by step

**1. Declare it public in a type that QML can see** (chapter 2):

```cpp
struct SystemData : public Qul::Singleton<SystemData>
{
    Qul::Property<int>  hours;
    Qul::Property<int>  minutes;
    Qul::Property<bool> use24Hour;
};
```

**2. Set it from wherever your data arrives:**

```cpp
void onRtcTick(int h, int m)
{
    SystemData::instance().hours.setValue(h);
    SystemData::instance().minutes.setValue(m);
}
```

**3. Bind to it in QML:**

```qml
Text {
    text: Format.clockText(SystemData.hours,
                           SystemData.minutes,
                           SystemData.use24Hour)
}
```

**4. Read it back in C++ when you need to:**

```cpp
if (SystemData::instance().use24Hour.value()) { ... }
```

Note `value()` to read, `setValue()` to write. A `Property` is not an `int`
with extra powers; it is a box. Forgetting `.value()` is the most common
compile error you will hit in week one.

## Which types can you use

Anything that maps to a QML type: `int`, `bool`, `float`, `double`,
`std::string`, your own `enum`, and `Qul::SharedImage` for pictures.

One rule from the docs:

> "Property type T that does not have built-in comparison operator must be
> provided with a user-defined operator==."

The engine compares old and new to decide whether anything actually changed. If
it cannot compare your type, give it an `operator==`. Without one you get a
compile error, which is the good outcome — the bad outcome would be a property
that updates every frame forever.

## Grouped properties

Put properties inside a plain struct and QML sees a group:

```cpp
struct Margins
{
    Qul::Property<int> left;
    Qul::Property<int> right;
};

struct Layout : public Qul::Singleton<Layout>
{
    Margins margins;
};
```

```qml
Item { x: Layout.margins.left }
```

Only public `Qul::Property` fields inside the group are exposed. Useful when a
singleton is getting wide and some of its properties clearly belong together.

## The integer trap, in detail

This one cost real days, so it gets its own section.

**QML has exactly one integer type.** Not `int8`, `int16`, `int32` — one.

Your hardware API will want narrow types, and that is correct: a CAN signal is
genuinely a `uint8_t`. The question is what you expose.

```cpp
Qul::Property<uint8_t>  maneuver;             // fine
Qul::Property<uint16_t> etaMinutes;           // fine as a property...
Qul::Signal<void(int button, int action)> buttonEvent;  // ...but widen for signals
```

Properties of narrow types work. Where it broke in this project was a desktop
bridge that mirrored narrow types across the boundary: 8-bit and 32-bit
survived, **16-bit did not**, and every number on the screen was garbage. The
comment in `ClusterInput.h` is the scar:

```cpp
// QML signal slots use its canonical int type; the hardware API stays byte-sized.
```

The rule that comes out of it: **narrow inside your own code, `int` at the QML
boundary** for anything in a signal signature, and be suspicious of any
sixteen-bit value crossing over.

## From this project

```cpp
// NavigationData.h                               from this project
struct NavigationData : public Qul::Singleton<NavigationData>
{
    enum Maneuver : uint8_t {
        None = 0, Straight, SlightLeft, Left, SharpLeft,
        SlightRight, Right, SharpRight, UTurnLeft, UTurnRight,
        RoundaboutEnter, RoundaboutExit, ForkLeft, ForkRight,
        MergeLeft, MergeRight, Destination
    };

    Qul::Property<bool>        active;
    Qul::Property<uint8_t>     maneuver;
    Qul::Property<uint8_t>     roundaboutExit;
    Qul::Property<uint32_t>    distanceToManeuverM;
    Qul::Property<uint32_t>    distanceRemainingM;
    Qul::Property<uint16_t>    etaMinutes;
    Qul::Property<uint8_t>     laneMask;
    Qul::Property<uint8_t>     recommendedLaneMask;
    Qul::Property<std::string> roadName;
};
```

Three things to copy from this:

- **The enum lives next to the property that uses it.** QML gets
  `NavigationData.SharpLeft` for free, so no screen has to know that sharp-left
  is 7.
- **Units are in the names.** `distanceToManeuverM`, `etaMinutes`. Nobody has to
  guess, and nobody divides by a thousand twice.
- **A `laneMask` is a bitfield in one property**, not eight booleans. Fewer
  properties means fewer bindings to re-evaluate.

## Traps

**You forget `.value()`.** Compile error, fixed in seconds. Harmless.

**You set a property every frame with the same value.** The engine compares and
will not re-run bindings for an unchanged value, so this is cheaper than it
looks — but it is still a call per frame. Set it when it changes.

**You add a property to drive a bit of UI state.** Properties are not free:
each one is storage plus the dirty-tracking around it. If QML can derive the
thing from a property you already have, let it.

**You expose a narrow type in a signal signature.** See above.

## Check it yourself

Count what you expose, and find the ones nothing reads:

```bash
grep -rhoE 'Qul::Property<[^>]+> +[a-zA-Z]+' --include='*.h' . | awk '{print $2}' | sort > /tmp/declared
for p in $(cat /tmp/declared); do
    n=$(grep -rc "\.$p\b" qml --include='*.qml' | awk -F: '{s+=$2} END {print s}')
    [ "$n" = "0" ] && echo "unread by QML: $p"
done
```

A property no QML file reads is either dead or a bug where the screen is
showing something stale.

## Sources

- [Qul::Property](https://doc.qt.io/QtForMCUs/qul-property.html)
- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
