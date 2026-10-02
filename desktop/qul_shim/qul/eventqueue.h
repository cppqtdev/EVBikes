#pragma once

#include <cstddef>

// Desktop: events are delivered immediately on the calling (UI) thread.
namespace Qul {

enum EventQueueOverrunPolicy { EventQueueOverrunPolicy_Discard, EventQueueOverrunPolicy_OverwriteOldest };

template <typename T,
          EventQueueOverrunPolicy overrunPolicy = EventQueueOverrunPolicy_Discard,
          std::size_t queueSize = 5>
class EventQueue
{
public:
    static_assert(queueSize > 0, "EventQueue capacity must be positive");
    static_assert(overrunPolicy == EventQueueOverrunPolicy_Discard
                      || overrunPolicy == EventQueueOverrunPolicy_OverwriteOldest,
                  "Unsupported EventQueue overrun policy");
    virtual ~EventQueue() = default;
    virtual void onEvent(const T &event) = 0;
    void postEvent(const T &event) { onEvent(event); }
    void postEventFromInterrupt(const T &event) { onEvent(event); }
};

} // namespace Qul
