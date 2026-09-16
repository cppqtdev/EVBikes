#pragma once

#include <cstdint>

namespace evb {

// Integer exponential moving average. shift=2 -> alpha 1/4.
class EmaFilter
{
public:
    explicit EmaFilter(uint8_t shift = 2) : m_shift(shift) {}

    int32_t update(int32_t sample)
    {
        if (!m_primed) {
            m_acc = sample * (1 << m_shift);
            m_primed = true;
        } else {
            m_acc += sample - (m_acc >> m_shift);
        }
        return m_acc >> m_shift;
    }

    void reset() { m_primed = false; }

private:
    int32_t m_acc = 0;
    uint8_t m_shift;
    bool m_primed = false;
};

// Signal must stay stable for `stableTicks` updates before output changes.
class Debouncer
{
public:
    explicit Debouncer(uint8_t stableTicks = 3) : m_needed(stableTicks) {}

    bool update(bool raw)
    {
        if (raw == m_state) {
            m_count = 0;
        } else if (++m_count >= m_needed) {
            m_state = raw;
            m_count = 0;
        }
        return m_state;
    }

    bool state() const { return m_state; }

private:
    uint8_t m_needed;
    uint8_t m_count = 0;
    bool m_state = false;
};

} // namespace evb
