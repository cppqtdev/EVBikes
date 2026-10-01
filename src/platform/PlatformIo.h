#pragma once

#include <cstddef>
#include <cstdint>

// Board specific hardware access. One implementation per target:
//   platform/sim/PlatformSim.cpp      desktop simulator
//   platform/board/PlatformBoard.cpp  MCU board (fill in the driver calls)
namespace evb::platform {

// Starts CAN, phone link (BLE module / UART) and GPIO inputs.
// Drivers deliver data through Backend::postCanFrame*/postPhoneBytes*.
void init();

uint32_t millis();

// Sends a ready-built link frame to the phone. Returns false if the link is down.
bool sendPhoneBytes(const uint8_t *data, std::size_t len);

void setBacklight(int percent);

// False when the target has no backlight to turn down, so brightness has to be
// applied to the picture instead of the panel.
bool hasBacklight();

} // namespace evb::platform
