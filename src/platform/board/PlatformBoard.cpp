#include "../PlatformIo.h"
#include "../../backend/Backend.h"

#include <platforminterface/platforminterface.h>

// Board bring-up template. Replace each TODO with the vendor SDK call.
//
// NXP i.MX RT1170 : FlexCAN (fsl_flexcan.h), LPUART (fsl_lpuart.h), GPIO (fsl_gpio.h), PWM backlight
// Infineon TRAVEO T2G : CAN FD (cy_canfd.h), SCB UART (cy_scb_uart.h), GPIO (cy_gpio.h)
// STM32 : FDCAN (stm32xxxx_hal_fdcan.h), UART (stm32xxxx_hal_uart.h), EXTI

namespace evb::platform {

namespace {

// TODO: call from the CAN RX interrupt after reading the message buffer.
[[maybe_unused]] void onCanRxIsr(uint32_t id, uint8_t dlc, const uint8_t *payload)
{
    CanFrame f;
    f.id = id;
    f.dlc = dlc > 8 ? 8 : dlc;
    for (uint8_t i = 0; i < f.dlc; ++i)
        f.data[i] = payload[i];
    f.timestampMs = millis();
    Backend::postCanFrameFromIsr(f);
}

// TODO: call from the UART RX interrupt (or DMA idle-line callback) of the BLE module.
[[maybe_unused]] void onPhoneUartRxIsr(const uint8_t *data, std::size_t len)
{
    Backend::postPhoneBytesFromIsr(data, len);
}

} // namespace

void init()
{
    // TODO: CAN 500 kbit/s, acceptance filter only for ids in core/can/CanIds.h
    // TODO: UART 115200 8N1 to BLE module (e.g. nRF52 / ESP32-C3 running the GATT bridge)
    // TODO: GPIO handlebar switch -> debounce -> ClusterInput::instance().inject() via an EventQueue
    // TODO: ambient light sensor -> SystemData::instance().nightMode
}

uint32_t millis()
{
    return static_cast<uint32_t>(Qul::Platform::getPlatformInstance()->currentTimestamp());
}

bool sendPhoneBytes(const uint8_t *data, std::size_t len)
{
    (void)data;
    (void)len;
    // TODO: UART DMA transmit
    return false;
}

void setBacklight(int percent)
{
    (void)percent;
    // TODO: PWM duty cycle
}

bool hasBacklight()
{
    return true;
}

} // namespace evb::platform
