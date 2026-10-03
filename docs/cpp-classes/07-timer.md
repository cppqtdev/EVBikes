# 07 — Qul::Timer

Run something later, or run it every N milliseconds.

```cpp
#include <qul/timer.h>

class Qul::Timer
```

> "Provides a way to run repetitive and single-shot timers."

```cpp
Timer(int interval = 0);
virtual ~Timer() override;        // stops the timer

void setInterval(int msec);
int  interval() const;
void setSingleShot(bool singleShot);
bool isSingleShot() const;

void start();
void start(int msec);
void stop();
bool isActive() const;

template <typename FuncArg> void onTimeout(const FuncArg &f);
```

## When you reach for it

- Poll a peripheral that has no interrupt
- Run a state machine tick
- Time out a connection that went quiet
- Dismiss a notification after three seconds
- Drive a simulation while you develop without hardware

## Step by step

**1. Hold it as a member.** Not a local — the destructor stops the timer, so a
timer on the stack stops the moment the function returns.

```cpp
struct Simulator : public Qul::Singleton<Simulator>
{
    void start();

private:
    void onRuntimeTick();
    Qul::Timer m_timer;
};
```

**2. Set the callback and the interval, then start:**

```cpp
void Simulator::start()
{
    m_timer.onTimeout([this] { onRuntimeTick(); });
    m_timer.setInterval(16);     // about 60 per second
    m_timer.start();
}
```

**3. Do the work in the callback:**

```cpp
void Simulator::onRuntimeTick()
{
    const uint32_t now = evb::platform::millis();
    const uint32_t gap = now - m_lastTickMs;
    m_lastTickMs = now;

    step(gap);
}
```

## Single shot

```cpp
m_timer.setSingleShot(true);
m_timer.start(3000);        // fires once, three seconds from now
```

Or just `start(msec)` on a repeating timer to set the interval and start in one
call.

## Four behaviours worth knowing

From the docs, each of these has bitten somebody:

- **A timer does not start by itself.** Constructing it with an interval does
  not start it. You must call `start()`.
- **"Setting the interval of an active timer does not change the next event."**
  Change the interval mid-flight and the *current* countdown finishes on the
  old one. Call `stop()` then `start()` if you need it to take effect now.
- **"Only the last callback stays active."** Calling `onTimeout()` twice
  replaces the first callback; it does not add a second. One timer, one
  handler.
- **The destructor stops it.** Which is good, and is why it must outlive the
  work it drives.

## Always clamp the elapsed time

This is not in the API, but it will save you.

Your callback almost certainly computes "how long since last time" and advances
something by that much. The first tick after startup, or after a long frame, or
after a debugger pause, can be enormous. Advance a state machine by two seconds
in one step and it jumps somewhere impossible.

```cpp
const uint32_t gap     = nowMs - m_lastTickMs;
const uint32_t elapsed = gap > kMaxTickMs ? kMaxTickMs : gap;
```

And watch for unsigned wraparound in the subtraction. In this project a
timestamp one millisecond ahead of the comparison time wrapped to four billion
and every node was declared dead, several times a second. Read the clock once,
in the right order, and clamp the result.

## Timer or EventQueue?

| You want | Use |
|---|---|
| Something to happen on a schedule | `Timer` |
| To react to something that already happened elsewhere | `EventQueue` |
| To poll a peripheral with no interrupt | `Timer` |
| To receive from a peripheral that has an interrupt | `EventQueue` |

A `Timer` is a source of events. An `EventQueue` is a channel for events you
did not create. If you find yourself polling a flag that an interrupt sets,
you wanted a queue.

## From this project

```cpp
// Simulator.h                                    from this project
struct Simulator : public Qul::Singleton<Simulator>
{
    Qul::Property<bool>    running;
    Qul::Property<uint8_t> scenario;
    Qul::Property<bool>    parked;

    Simulator();

    void start();
    void stop();
    void step(uint32_t elapsedMs);
    void nextScenario();
    void togglePark();
    void cycleRideMode();

private:
    void onRuntimeTick();

    Qul::Timer m_timer;
    uint32_t   m_lastTickMs = 0;
    uint32_t   m_pollElapsedMs = 0;
    uint32_t   m_clockElapsedMs = 0;
    bool       m_started = false;
};
```

Two details worth copying:

- **One timer drives several rates.** `m_pollElapsedMs` and `m_clockElapsedMs`
  accumulate, and the code acts when each passes its own threshold. One timer
  at 16 ms serves a 16 ms animation, a 200 ms poll and a 1000 ms clock. Three
  timers would cost three times the bookkeeping for nothing.
- **`m_started` guards against a double start.** Calling `start()` twice on a
  running timer is not an error, but the surrounding state usually assumes it
  happened once.

## Traps

**The timer is a local variable.** It is destroyed, and therefore stopped, at
the end of the function. Nothing fires and nothing warns you.

**You call `onTimeout()` in a loop.** Only the last one survives.

**You change the interval and expect it to apply now.** It applies after the
current countdown.

**You do not clamp the elapsed time.** The first tick is always the long one.

**You do heavy work in the callback.** It runs on the main loop. A callback
that takes 20 ms costs you a frame at 60 fps, every time it runs.

## Check it yourself

A timer that is not a member is a bug:

```bash
grep -rn "Qul::Timer" --include='*.h' --include='*.cpp' .
```

Each hit should be a class member or a file-scope static, never a local.

## Sources

- [Qul::Timer](https://doc.qt.io/QtForMCUs/qul-timer.html)
