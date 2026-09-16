#pragma once

// Desktop: events are delivered immediately on the calling (UI) thread.
namespace Qul {

template <typename T>
class EventQueue
{
public:
    virtual ~EventQueue() = default;
    virtual void onEvent(const T &event) = 0;
    void postEvent(const T &event) { onEvent(event); }
    void postEventFromInterrupt(const T &event) { onEvent(event); }
};

} // namespace Qul
