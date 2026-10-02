#pragma once

#include <cstdint>

namespace evb {

// Preserve sub-metre travel between CAN updates. speedX10 is 0.1 km/h.
class DistanceIntegrator
{
public:
    uint32_t advance(uint16_t speedX10, uint32_t elapsedMs)
    {
        const uint64_t total = static_cast<uint64_t>(speedX10) * elapsedMs + m_remainder;
        m_remainder = static_cast<uint16_t>(total % 36000u);
        return static_cast<uint32_t>(total / 36000u);
    }

private:
    uint16_t m_remainder = 0;
};

} // namespace evb
