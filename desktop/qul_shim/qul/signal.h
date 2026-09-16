#pragma once

#include <functional>
#include <utility>

namespace Qul {

template <typename Fn>
class Signal
{
public:
    template <typename... Args>
    void operator()(Args &&...args)
    {
        if (m_slot)
            m_slot(std::forward<Args>(args)...);
    }

    void connect(std::function<Fn> slot) { m_slot = std::move(slot); }

private:
    std::function<Fn> m_slot;
};

} // namespace Qul
