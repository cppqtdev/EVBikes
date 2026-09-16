#pragma once

#include <cstdint>

namespace evb {

struct CanFrame
{
    uint32_t id = 0;
    uint8_t dlc = 0;
    uint8_t data[8] = {};
    uint32_t timestampMs = 0;
};

// Intel (little-endian) bit extraction, DBC style start bit.
inline uint32_t canGetBitsLE(const uint8_t *data, uint8_t startBit, uint8_t length)
{
    uint32_t value = 0;
    for (uint8_t i = 0; i < length; ++i) {
        const uint16_t bit = startBit + i;
        if (data[bit / 8] & (1u << (bit % 8)))
            value |= (1u << i);
    }
    return value;
}

inline int32_t canGetSignedLE(const uint8_t *data, uint8_t startBit, uint8_t length)
{
    uint32_t raw = canGetBitsLE(data, startBit, length);
    if (length < 32 && (raw & (1u << (length - 1))))
        raw |= ~((1u << length) - 1);
    return static_cast<int32_t>(raw);
}

inline void canSetBitsLE(uint8_t *data, uint8_t startBit, uint8_t length, uint32_t value)
{
    for (uint8_t i = 0; i < length; ++i) {
        const uint16_t bit = startBit + i;
        const uint8_t mask = static_cast<uint8_t>(1u << (bit % 8));
        if (value & (1u << i))
            data[bit / 8] |= mask;
        else
            data[bit / 8] &= static_cast<uint8_t>(~mask);
    }
}

} // namespace evb
