#include "../PlatformIo.h"

#include <chrono>
#include <cstdio>

namespace evb::platform {

void init()
{
    std::printf("[sim] platform init: data comes from Simulator.step()\n");
}

uint32_t millis()
{
    using namespace std::chrono;
    static const auto start = steady_clock::now();
    return static_cast<uint32_t>(duration_cast<milliseconds>(steady_clock::now() - start).count());
}

bool sendPhoneBytes(const uint8_t *data, std::size_t len)
{
    std::printf("[sim] -> phone type=0x%02X len=%u\n", len > 2 ? data[2] : 0, static_cast<unsigned>(len));
    return true;
}

void setBacklight(int percent)
{
    std::printf("[sim] backlight %d%%\n", percent);
}

} // namespace evb::platform
