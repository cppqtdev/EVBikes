# 04 — Qul::Signal

A property says *what is true*. A signal says *what just happened*.

```cpp
#include <qul/signal.h>

template <typename T> struct Qul::Signal
```

> "Allows creating a signal that can be connected from QML."

Two member functions:

```cpp
bool isConnected() const
void operator()() const      // plus the arguments your signature declares
```

## When you reach for it

When the thing is an **event**, not a **state**.

| The thing | It is a | Use |
|---|---|---|
| The speed is 52 | state | `Property` |
| The rider pressed OK | event | `Signal` |
| The battery is at 80% | state | `Property` |
| A text message arrived | event | `Signal` |
| The left indicator is on | state | `Property` |
| The trip counter was reset | event | `Signal` |

The test: **if you missed it, does it matter?** A state you can read at any
time; if you miss the moment it changed, you still know the value. An event
that you miss is gone. Button presses are gone. Speeds are not.

Get this wrong in the state direction and nothing breaks, you just have a
clumsy API. Get it wrong in the event direction — modelling a button press as
a boolean property — and you get a UI that misses fast double presses and
occasionally latches on, which is miserable to debug.

## Step by step

**1. Declare it, with the full function signature including parameter names:**

```cpp
struct ClusterInput : public Qul::Singleton<ClusterInput>
{
    Qul::Signal<void(int button, int action)> buttonEvent;
};
```

The parameter names matter. `qmlinterfacegenerator` exposes them to QML, and
they become the names you use in the handler. Nameless parameters give you a
signal you cannot read comfortably.

**2. Emit it from C++ by calling it:**

```cpp
void ClusterInput::inject(uint8_t button, uint8_t action)
{
    buttonEvent(button, action);
}
```

It is a function object. `buttonEvent(...)` is the emit.

**3. Handle it in QML** with `on` plus the capitalised name:

```qml
import ClusterBackend

Item {
    Connections {
        target: ClusterInput
        onButtonEvent: {
            if (button === ClusterInput.Ok && action === ClusterInput.Press)
                Router.activate()
        }
    }
}
```

`buttonEvent` becomes `onButtonEvent`. Inside the handler the parameters are in
scope by the names you declared.

## The benefit

Without a signal you would have to poll: give QML a counter property, have it
notice the counter changed, work out what the press was. That is more state,
more bindings, and it still loses presses that arrive in the same frame.

A signal costs nothing when nothing happens, and delivers exactly once when
something does.

## isConnected()

```cpp
if (buttonEvent.isConnected())
    buttonEvent(button, action);
```

Useful when producing the arguments is expensive and the screen that cares is
not loaded. For a couple of integers, do not bother — the check costs about as
much as the call.

## From this project

```cpp
// ClusterInput.h                                 from this project
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

The whole input system is one signal. Note:

- **The signature takes `int`, the function takes `uint8_t`.** Deliberate, and
  commented. QML has one integer type; the hardware API does not have to care.
- **`inject()` is the seam.** The real driver calls it from a GPIO handler; the
  desktop simulator calls it from a keyboard event. QML cannot tell, and both
  can be tested.
- **The enums travel with it**, so QML writes `ClusterInput.Ok` rather than `4`.

## Traps

**You give the signature unnamed parameters.** `Qul::Signal<void(int, int)>`
compiles, but the QML handler has nothing sensible to call them.

**You emit from an interrupt.** Do not. A signal runs its handlers
synchronously, which means QML code on the interrupt stack. Post to an
`EventQueue` instead (chapter 6) and emit from the queue's `onEvent`.

**You use a signal where a property belongs.** If QML's handler is just
assigning the value to something it keeps, that was a property.

**You expect a return value.** Signals are `void`. QML cannot hand anything
back.

## Check it yourself

Every signal should have at least one handler:

```bash
for s in $(grep -rhoE 'Qul::Signal<[^>]+> +[a-zA-Z]+' --include='*.h' . | awk '{print $2}'); do
    h="on$(echo ${s:0:1} | tr a-z A-Z)${s:1}"
    grep -rq "$h" qml --include='*.qml' || echo "no QML handler for: $s  (expected $h)"
done
```

## Sources

- [Qul::Signal](https://doc.qt.io/QtForMCUs/qul-signal.html)
- [Integrating C++ code with QML](https://doc.qt.io/QtForMCUs/qtul-integratecppqml.html)
