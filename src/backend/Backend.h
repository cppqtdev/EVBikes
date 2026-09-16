#pragma once

#include "../core/can/CanFrame.h"
#include "../core/nav/PhoneLinkProtocol.h"

#include <cstddef>
#include <cstdint>

// Glue between drivers (any thread / ISR) and the UI thread singletons.
namespace Backend {

void init();

void postCanFrame(const evb::CanFrame &frame);
void postCanFrameFromIsr(const evb::CanFrame &frame);

void postPhoneBytes(const uint8_t *data, std::size_t len);
void postPhoneBytesFromIsr(const uint8_t *data, std::size_t len);

// UI thread only.
void periodic(uint32_t nowMs);
bool sendToPhone(evb::link::MsgType type, const uint8_t *payload, std::size_t len);

} // namespace Backend
