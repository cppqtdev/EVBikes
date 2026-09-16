#pragma once

#include <array>
#include <atomic>
#include <cstddef>

namespace evb {

// Single-producer / single-consumer lock-free queue.
// Producer: ISR or driver task. Consumer: decoder task.
template <typename T, std::size_t Capacity>
class RingBuffer
{
public:
    bool push(const T &item)
    {
        const std::size_t head = m_head.load(std::memory_order_relaxed);
        const std::size_t next = (head + 1) % Capacity;
        if (next == m_tail.load(std::memory_order_acquire))
            return false;
        m_data[head] = item;
        m_head.store(next, std::memory_order_release);
        return true;
    }

    bool pop(T &item)
    {
        const std::size_t tail = m_tail.load(std::memory_order_relaxed);
        if (tail == m_head.load(std::memory_order_acquire))
            return false;
        item = m_data[tail];
        m_tail.store((tail + 1) % Capacity, std::memory_order_release);
        return true;
    }

    bool empty() const
    {
        return m_head.load(std::memory_order_acquire) == m_tail.load(std::memory_order_acquire);
    }

private:
    std::array<T, Capacity> m_data{};
    std::atomic<std::size_t> m_head{0};
    std::atomic<std::size_t> m_tail{0};
};

} // namespace evb
