#pragma once

#include <cstdint>

namespace evb::canid {

constexpr uint32_t VcuStatus = 0x101;
constexpr uint32_t MotorStatus = 0x102;
constexpr uint32_t BmsStatus = 0x201;
constexpr uint32_t BmsRange = 0x202;
constexpr uint32_t BodyLamps = 0x301;
constexpr uint32_t AbsStatus = 0x302;
constexpr uint32_t Tpms = 0x401;
constexpr uint32_t Odometer = 0x501;
constexpr uint32_t Faults = 0x7A0;

} // namespace evb::canid
