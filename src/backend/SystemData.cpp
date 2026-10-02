#include "SystemData.h"

#include "AlertData.h"
#include "Backend.h"
#include "../platform/PlatformIo.h"

namespace {

constexpr uint16_t kDefaultPin = 1234;
constexpr uint8_t kMaxPinAttempts = 3;
constexpr uint8_t kProfileCount = 3;
constexpr int8_t kMaxSeatLevel = 5;
constexpr bool kEnrolledProfiles[kProfileCount] = {true, true, false};

uint32_t g_clockBaseMs = 0;
int32_t g_clockBaseSecondsOfDay = 0;

} // namespace

SystemData::SystemData()
{
    use24Hour.setValue(false);
    useMiles.setValue(false);
    brightness.setValue(80);
    softwareDimming.setValue(!evb::platform::hasBacklight());
    locked.setValue(true);
    pinAttemptsLeft.setValue(kMaxPinAttempts);
    demoMode.setValue(true);
    authState.setValue(AuthIdle);
    profileIndex.setValue(1);
    seatLevel.setValue(2);
    autoTurnOff.setValue(true);
    speedoStyle.setValue(SpeedoClassic);
    antiTheftArmed.setValue(false);
    theftCaptures.setValue(1);
    uptimeMs.setValue(0);
    splashStep.setValue(0);
    authElapsedMs.setValue(0);
    preRideElapsedMs.setValue(0);
    menuHintVisible.setValue(false);
    notificationToastVisible.setValue(false);
}

void SystemData::setClock(uint32_t unixSeconds, int16_t utcOffsetMinutes)
{
    const int64_t local = static_cast<int64_t>(unixSeconds) + static_cast<int32_t>(utcOffsetMinutes) * 60;
    g_clockBaseSecondsOfDay = static_cast<int32_t>(((local % 86400) + 86400) % 86400);
    g_clockBaseMs = evb::platform::millis();
    clockValid.setValue(true);
    tick();
}

void SystemData::advanceRuntime(uint32_t elapsedMs)
{
    uptimeMs.setValue(uptimeMs.value() + elapsedMs);

    m_splashElapsedMs += elapsedMs;
    while (m_splashElapsedMs >= 220 && splashStep.value() < 40) {
        m_splashElapsedMs -= 220;
        splashStep.setValue(static_cast<uint8_t>(splashStep.value() + 1));
    }

    if (authState.value() == AuthScanning || authState.value() == AuthMatched) {
        const uint32_t elapsed = static_cast<uint32_t>(m_authElapsedMs) + elapsedMs;
        m_authElapsedMs = static_cast<uint16_t>(elapsed > 65535 ? 65535 : elapsed);
        authElapsedMs.setValue(m_authElapsedMs);
        if (authState.value() == AuthScanning && m_authElapsedMs >= 1600)
            completeScan();
    }

    if (m_preRideReady) {
        const uint32_t elapsed = static_cast<uint32_t>(m_preRideElapsedMs) + elapsedMs;
        m_preRideElapsedMs = static_cast<uint16_t>(elapsed > 65535 ? 65535 : elapsed);
        preRideElapsedMs.setValue(m_preRideElapsedMs);
    }

    if (m_menuHintRemainingMs > 0) {
        m_menuHintRemainingMs = elapsedMs >= m_menuHintRemainingMs
            ? 0 : static_cast<uint16_t>(m_menuHintRemainingMs - elapsedMs);
        if (m_menuHintRemainingMs == 0)
            menuHintVisible.setValue(false);
    }
    if (m_toastRemainingMs > 0) {
        m_toastRemainingMs = elapsedMs >= m_toastRemainingMs
            ? 0 : static_cast<uint16_t>(m_toastRemainingMs - elapsedMs);
        if (m_toastRemainingMs == 0)
            notificationToastVisible.setValue(false);
    }
}

void SystemData::poll()
{
    Backend::periodic(evb::platform::millis());
}

void SystemData::setPreRideReady(bool ready)
{
    m_preRideReady = ready;
    m_preRideElapsedMs = 0;
    preRideElapsedMs.setValue(0);
}

void SystemData::showMenuHint()
{
    m_menuHintRemainingMs = 2000;
    menuHintVisible.setValue(true);
}

void SystemData::showNotificationToast()
{
    m_toastRemainingMs = 4000;
    notificationToastVisible.setValue(true);
}

void SystemData::tick()
{
    const uint32_t now = evb::platform::millis();
    AlertData::instance().tickSecond();

    if (!clockValid.value())
        return;
    const uint32_t elapsed = (now - g_clockBaseMs) / 1000;
    const uint32_t secondsOfDay = (static_cast<uint32_t>(g_clockBaseSecondsOfDay) + elapsed) % 86400;
    hours.setValue(static_cast<uint8_t>(secondsOfDay / 3600));
    minutes.setValue(static_cast<uint8_t>((secondsOfDay / 60) % 60));
}

bool SystemData::submitPin(uint16_t pin)
{
    if (pinAttemptsLeft.value() <= 0)
        return false;
    if (pin == kDefaultPin) {
        locked.setValue(false);
        pinAttemptsLeft.setValue(kMaxPinAttempts);
        return true;
    }
    pinAttemptsLeft.setValue(pinAttemptsLeft.value() - 1);
    return false;
}

void SystemData::setBrightnessLevel(uint8_t level)
{
    const uint8_t clamped = level < 10 ? 10 : (level > 100 ? 100 : level);
    brightness.setValue(clamped);
    evb::platform::setBacklight(clamped);
}

void SystemData::toggleClockFormat()
{
    use24Hour.setValue(!use24Hour.value());
}

void SystemData::toggleUnits()
{
    useMiles.setValue(!useMiles.value());
}

void SystemData::selectProfile(int16_t index)
{
    profileIndex.setValue(static_cast<uint8_t>((index % kProfileCount + kProfileCount) % kProfileCount));
    if (authState.value() == AuthDenied)
        authState.setValue(AuthIdle);
}

void SystemData::startScan()
{
    if (authState.value() == AuthScanning)
        return;
    authState.setValue(AuthScanning);
    m_authElapsedMs = 0;
    authElapsedMs.setValue(0);
}

// Called by the fingerprint driver when the sensor has a result.
// The demo UI calls it after a short delay; profile 3 is not enrolled.
void SystemData::completeScan()
{
    if (authState.value() != AuthScanning)
        return;
    const bool ok = kEnrolledProfiles[profileIndex.value()];
    m_authElapsedMs = 0;
    authElapsedMs.setValue(0);
    authState.setValue(ok ? AuthMatched : AuthDenied);
    locked.setValue(!ok);
}

void SystemData::setSeatLevel(int8_t level)
{
    seatLevel.setValue(static_cast<uint8_t>(level < 0 ? 0 : (level > kMaxSeatLevel ? kMaxSeatLevel : level)));
}

void SystemData::toggleSpeedoStyle()
{
    speedoStyle.setValue(speedoStyle.value() == SpeedoClassic ? SpeedoHex : SpeedoClassic);
}

void SystemData::clearTheftCaptures()
{
    theftCaptures.setValue(0);
}
