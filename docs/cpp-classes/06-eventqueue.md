# 06 — Qul::EventQueue

The safe way to get data from an interrupt or another thread into the UI.

```cpp
#include <qul/eventqueue.h>

template <typename EventType_,
          Qul::EventQueueOverrunPolicy overrunPolicy = EventQueueOverrunPolicy_Discard,
          size_t queueSize = 5>
class Qul::EventQueue
```

Three template parameters, and **the defaults are the trap**. More on that
below.

```cpp
void postEvent(const EventType &event);
void postEventFromInterrupt(const EventType &event);

virtual void onEvent(const EventType &event) = 0;   // you implement this
virtual void onEventDiscarded(const EventType &event);
virtual void onQueueOverrun();

bool isOverrun() const;      // since 2.3
void clearOverrun();         // since 2.3
```

## The problem it solves

A CAN frame arrives. You are in an interrupt handler. You must not touch the
UI from here: the engine is not reentrant, and a QML binding running on the
interrupt stack is a crash waiting for the wrong moment.

So you need a hand-off. The interrupt writes somewhere cheap and returns; the
main loop picks it up later and does the real work. That is an `EventQueue`.

## Step by step

**1. Define a POD event type.** Events are copied with `memcpy`, so it must be
plain data or pointers — no `std::string`, no constructors that matter.

```cpp
struct CanFrame
{
    uint32_t id;
    uint8_t  len;
    uint8_t  data[8];
};
```

**2. Subclass the queue and implement `onEvent`:**

```cpp
class CanQueue : public Qul::EventQueue<CanFrame,
                                        Qul::EventQueueOverrunPolicy_Discard,
                                        16>
{
public:
    void onEvent(const CanFrame &frame) override
    {
        g_decoder.decode(frame);     // runs on the main loop, safe
    }
};
```

**3. Give it somewhere to live:**

```cpp
CanQueue &canQueue()
{
    static CanQueue q;
    return q;
}
```

**4. Post from the interrupt:**

```cpp
extern "C" void CAN0_IRQHandler()
{
    CanFrame f = readFrameFromPeripheral();
    canQueue().postEventFromInterrupt(f);   // note: FromInterrupt
}
```

`postEvent` from normal code, `postEventFromInterrupt` from an ISR. Use the
right one.

**5. Nothing else.** The engine drains the queue and calls `onEvent` for you.

## The benefit

The interrupt stays short — a memcpy and a return. The decoding, and the
property writes that follow it, happen on the main loop where they are safe.
You get that for about twenty lines.

## The defaults are a trap

```cpp
size_t queueSize = 5
```

**Five.** That is the default, and it is almost certainly too small.

In this project, eight CAN frames were posted per tick into a queue of five.
Three were dropped every tick, silently, forever. The desktop shim delivers
events synchronously, so it hid the problem completely — the bug only existed
on hardware, and only showed as data that was quietly wrong.

The sizes in use now:

```cpp
class CanQueue   : public Qul::EventQueue<evb::CanFrame, Qul::EventQueueOverrunPolicy_Discard, 16>
class PhoneQueue : public Qul::EventQueue<PhoneChunk,    Qul::EventQueueOverrunPolicy_Discard, 32>
```

**How to size it:** count the worst-case events between two drains, then double
it. A drain happens once per frame, so at 60 fps that is 16 ms of arrivals. If
your bus can deliver 20 frames in 16 ms, 5 will not do.

## The overrun policy

```cpp
EventQueueOverrunPolicy_Discard   // drop the new event
EventQueueOverrunPolicy_Overwrite // drop the oldest
```

Which is right depends on what the data means:

- **Discard** for a stream where every item matters and losing a recent one is
  as bad as losing an old one — protocol chunks, keypresses.
- **Overwrite** for a sampled value where only the latest matters — a sensor
  reading. Losing an old sample is free.

When it overflows, `onQueueOverrun()` is scheduled. **Override it and count
the overruns.** An overrun you cannot see is a bug you will chase for days:

```cpp
void onQueueOverrun() override { ++g_canOverruns; }
```

Then put `g_canOverruns` on a debug overlay. Since 2.3 you can also poll
`isOverrun()` and `clearOverrun()`.

## Interrupt and thread safety

Straight from the docs, because the detail matters:

On **baremetal**, the DoubleQueue backend "is interrupt-safe as long as there
is a single writer, because writes and reads are directed to different lists."
Two interrupts posting to the same queue is **not** safe without your own
synchronisation.

On platforms **with threads or an RTOS**, the queue is thread-safe using
mutexes or RTOS queues.

The draining operation is safe to be interrupted either way.

So: one writer per queue. If two sources feed the same data, give them a queue
each, or guard the post.

## When NOT to use it

An `EventQueue` is for **crossing a boundary** — interrupt to main loop, thread
to main loop. It is not a general message bus.

If both ends are already on the main loop, just call the function. Posting to
a queue adds a frame of latency, a fixed-size buffer that can overflow, and a
POD restriction, in exchange for nothing.

## From this project

```cpp
// src/backend/Backend.cpp                        from this project
class CanQueue : public Qul::EventQueue<evb::CanFrame, Qul::EventQueueOverrunPolicy_Discard, 16>
{
public:
    void onEvent(const evb::CanFrame &frame) override
    {
        g_decoder.decode(frame);
    }
};

class PhoneQueue : public Qul::EventQueue<PhoneChunk, Qul::EventQueueOverrunPolicy_Discard, 32>
{
public:
    void onEvent(const PhoneChunk &chunk) override
    {
        if (evb::platform::isSimulator()
            && ConnectivityData::instance().bluetoothState.value() != ConnectivityData::Connected)
            return;
        g_lastPhoneRxMs = evb::platform::millis();
        PhoneData::instance().connected.setValue(true);
        g_phoneParser.feed(chunk.data, chunk.len);
    }
};
```

Two queues, two sizes, chosen from the two buses' actual rates. Both write into
singletons from `onEvent`, which is exactly where it is safe to do so.

## Traps

**You keep the default size of 5.** Almost always wrong. Size it from your
data rate.

**You do not override `onQueueOverrun()`.** Drops are then invisible.

**You post a non-POD type.** It is memcpy'd. A `std::string` in an event will
compile and then corrupt.

**You post pointers with the discard policy.** From the docs: the provided
backends "do not manage memory when the events are pointers." A discarded
pointer is a leak you have to handle yourself.

**You test only on desktop.** The shim delivers synchronously and never
overflows. Queue bugs do not exist there.

## Check it yourself

Find every queue and its size:

```bash
grep -rn "Qul::EventQueue<" --include='*.cpp' --include='*.h' .
```

For each, ask: how many events can arrive between two frames, worst case? And:
is `onQueueOverrun` overridden?

## Sources

- [Qul::EventQueue](https://doc.qt.io/QtForMCUs/qul-eventqueue.html)
