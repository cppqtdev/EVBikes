#include "SystemData.h"

#include "AlertData.h"
#include "Backend.h"
#include "../platform/PlatformIo.h"

namespace {

constexpr int kDefaultPin = 1234;
constexpr int kMaxPinAttempts = 3;
constexpr int kProfileCount = 3;
constexpr int kMaxSeatLevel = 5;
constexpr bool kEnrolledProfiles[kProfileCount] = {true, true, false};

uint32_t g_clockBaseMs = 0;
int32_t g_clockBaseSecondsOfDay = 0;

} // namespace

SystemData::SystemData()
{
    use24Hour.setValue(false);
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
}

void SystemData::setClock(int unixSeconds, int utcOffsetMinutes)
{
    const int64_t local = static_cast<int64_t>(static_cast<uint32_t>(unixSeconds)) + utcOffsetMinutes * 60;
    g_clockBaseSecondsOfDay = static_cast<int32_t>(((local % 86400) + 86400) % 86400);
    g_clockBaseMs = evb::platform::millis();
    clockValid.setValue(true);
    tick();
}

// Runs several times a second: node timeouts and alert thresholds have to be
// noticed sooner than the once-a-second clock work below.
void SystemData::poll()
{
    Backend::periodic(evb::platform::millis());
}

void SystemData::tick()
{
    const uint32_t now = evb::platform::millis();
    AlertData::instance().tickSecond();

    if (!clockValid.value())
        return;
    const uint32_t elapsed = (now - g_clockBaseMs) / 1000;
    const uint32_t secondsOfDay = (static_cast<uint32_t>(g_clockBaseSecondsOfDay) + elapsed) % 86400;
    hours.setValue(static_cast<int>(secondsOfDay / 3600));
    minutes.setValue(static_cast<int>((secondsOfDay / 60) % 60));
}

bool SystemData::submitPin(int pin)
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

void SystemData::setBrightnessLevel(int level)
{
    const int clamped = level < 10 ? 10 : (level > 100 ? 100 : level);
    brightness.setValue(clamped);
    evb::platform::setBacklight(clamped);
}

void SystemData::toggleClockFormat()
{
    use24Hour.setValue(!use24Hour.value());
}

void SystemData::selectProfile(int index)
{
    profileIndex.setValue((index % kProfileCount + kProfileCount) % kProfileCount);
    if (authState.value() == AuthDenied)
        authState.setValue(AuthIdle);
}

void SystemData::startScan()
{
    if (authState.value() == AuthScanning)
        return;
    authState.setValue(AuthScanning);
}

// Called by the fingerprint driver when the sensor has a result.
// The demo UI calls it after a short delay; profile 3 is not enrolled.
void SystemData::completeScan()
{
    if (authState.value() != AuthScanning)
        return;
    const bool ok = kEnrolledProfiles[profileIndex.value()];
    authState.setValue(ok ? AuthMatched : AuthDenied);
    locked.setValue(!ok);
}

void SystemData::setSeatLevel(int level)
{
    seatLevel.setValue(level < 0 ? 0 : (level > kMaxSeatLevel ? kMaxSeatLevel : level));
}

void SystemData::toggleSpeedoStyle()
{
    speedoStyle.setValue(speedoStyle.value() == SpeedoClassic ? SpeedoHex : SpeedoClassic);
}

void SystemData::clearTheftCaptures()
{
    theftCaptures.setValue(0);
}
