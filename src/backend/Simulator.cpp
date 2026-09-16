#include "Simulator.h"

#include "Backend.h"
#include "../core/can/CanIds.h"
#include "../platform/PlatformIo.h"

#include <cstring>

namespace {

enum Scenario { CityEco = 0, SportRun, LowTyre, Overheat, Crash, ScenarioCount };

constexpr int kBootStandDownMs = 11000;
constexpr int kBootParkedMs = 14000;

struct SimState
{
    int timeMs = 0;
    int speedX10 = 0;
    int targetSpeedX10 = 450;
    int socX10 = 820;
    int packTemp = 34;
    int motorTemp = 48;
    int rearPsiX10 = 320;
    uint32_t odoX10 = 123560;
    uint32_t tripX10 = 90;
    int navDistance = 850;
    int navStep = 0;
    int phoneTimerMs = 0;
    int blinkMs = 0;
    bool blinkOn = false;
};

SimState g;

evb::CanFrame makeFrame(uint32_t id, uint8_t dlc)
{
    evb::CanFrame f;
    f.id = id;
    f.dlc = dlc;
    f.timestampMs = evb::platform::millis();
    return f;
}

void approach(int &value, int target, int step)
{
    if (value < target) value = (value + step > target) ? target : value + step;
    else if (value > target) value = (value - step < target) ? target : value - step;
}

struct NavStep
{
    evb::link::Maneuver maneuver;
    int distance;
    const char *road;
};

constexpr NavStep kRoute[] = {
    {evb::link::Maneuver::Right, 850, "MG Road"},
    {evb::link::Maneuver::Straight, 1200, "Outer Ring Road"},
    {evb::link::Maneuver::RoundaboutEnter, 600, "Silk Board Junction"},
    {evb::link::Maneuver::SlightLeft, 400, "Hosur Road"},
    {evb::link::Maneuver::Left, 300, "Electronic City Phase 1"},
    {evb::link::Maneuver::Destination, 150, "Office"},
};
constexpr int kRouteLen = sizeof(kRoute) / sizeof(kRoute[0]);

void sendPhoneTraffic(int scenario)
{
    uint8_t frame[evb::link::kMaxFrame];

    evb::link::NavUpdate nav;
    const NavStep &step = kRoute[g.navStep];
    nav.maneuver = step.maneuver;
    nav.roundaboutExit = step.maneuver == evb::link::Maneuver::RoundaboutEnter ? 2 : 0;
    nav.distanceToManeuverM = static_cast<uint32_t>(g.navDistance);
    uint32_t remaining = static_cast<uint32_t>(g.navDistance);
    for (int i = g.navStep + 1; i < kRouteLen; ++i)
        remaining += static_cast<uint32_t>(kRoute[i].distance);
    nav.distanceRemainingM = remaining;
    nav.etaMinutes = static_cast<uint16_t>(remaining / 400 + 1);
    nav.laneMask = 0x07;
    nav.recommendedLaneMask = step.maneuver == evb::link::Maneuver::Right ? 0x04 : 0x02;
    std::strncpy(nav.roadName, step.road, evb::link::kMaxText);
    std::size_t n = evb::link::encodeNavUpdate(nav, frame, sizeof(frame));
    Backend::postPhoneBytes(frame, n);

    const uint8_t status[] = {76, 4, 1};
    n = evb::link::buildFrame(evb::link::MsgType::PhoneStatus, status, sizeof(status), frame, sizeof(frame));
    Backend::postPhoneBytes(frame, n);

    static const char kTitle[] = "Dandelions";
    static const char kArtist[] = "Ruth B.";
    uint8_t media[64];
    std::size_t m = 0;
    media[m++] = 1;
    media[m++] = 60;
    const int pos = (g.timeMs / 1000) % 233;
    media[m++] = static_cast<uint8_t>(pos);
    media[m++] = static_cast<uint8_t>(pos >> 8);
    media[m++] = 233;
    media[m++] = 0;
    media[m++] = sizeof(kTitle) - 1;
    std::memcpy(media + m, kTitle, sizeof(kTitle) - 1);
    m += sizeof(kTitle) - 1;
    media[m++] = sizeof(kArtist) - 1;
    std::memcpy(media + m, kArtist, sizeof(kArtist) - 1);
    m += sizeof(kArtist) - 1;
    n = evb::link::buildFrame(evb::link::MsgType::MediaState, media, m, frame, sizeof(frame));
    Backend::postPhoneBytes(frame, n);

    (void)scenario;
}

void sendTimeSyncOnce()
{
    static bool sent = false;
    if (sent)
        return;
    sent = true;
    const uint32_t unixTime = 1789551060u;
    const int16_t offset = 330;
    const uint8_t payload[] = {
        static_cast<uint8_t>(unixTime), static_cast<uint8_t>(unixTime >> 8),
        static_cast<uint8_t>(unixTime >> 16), static_cast<uint8_t>(unixTime >> 24),
        static_cast<uint8_t>(offset), static_cast<uint8_t>(offset >> 8)};
    uint8_t frame[evb::link::kMaxFrame];
    const std::size_t n = evb::link::buildFrame(evb::link::MsgType::TimeSync, payload, sizeof(payload), frame, sizeof(frame));
    Backend::postPhoneBytes(frame, n);
}

} // namespace

Simulator::Simulator()
{
    running.setValue(true);
    scenario.setValue(CityEco);
    parked.setValue(false);
}

void Simulator::togglePark()
{
    parked.setValue(!parked.value());
}

void Simulator::nextScenario()
{
    const int next = (scenario.value() + 1) % ScenarioCount;
    scenario.setValue(next);
    g.rearPsiX10 = 320;
    g.packTemp = 34;
    g.motorTemp = 48;
}

void Simulator::step(int elapsedMs)
{
    if (!running.value())
        return;

    const int sc = scenario.value();
    g.timeMs += elapsedMs;
    sendTimeSyncOnce();

    const int phase = (g.timeMs / 1000) % 40;
    if (sc == SportRun && !parked.value())
        g.targetSpeedX10 = phase < 25 ? 980 : 300;
    else if (sc == Crash || parked.value())
        g.targetSpeedX10 = 0;
    else if (g.timeMs < kBootParkedMs)
        g.targetSpeedX10 = 0;
    else
        g.targetSpeedX10 = phase < 5 ? 0 : (phase < 30 ? 520 : 250);
    approach(g.speedX10, g.targetSpeedX10, sc == SportRun ? 12 : 6);

    const int accel = g.targetSpeedX10 - g.speedX10;
    const int currentX10 = g.speedX10 == 0 ? 0 : (accel > 0 ? 900 + accel * 8 : (accel < 0 ? -300 : 350));
    const int rpm = g.speedX10 * 9;

    g.odoX10 += static_cast<uint32_t>(g.speedX10 * elapsedMs / 360000);
    g.tripX10 += static_cast<uint32_t>(g.speedX10 * elapsedMs / 360000);
    if (g.timeMs % 3000 < elapsedMs && g.socX10 > 60)
        g.socX10 -= 1;

    if (sc == LowTyre) approach(g.rearPsiX10, 265, 1);
    if (sc == Overheat) { approach(g.packTemp, 62, 1); approach(g.motorTemp, 118, 1); }

    g.blinkMs += elapsedMs;
    if (g.blinkMs >= 400) {
        g.blinkMs = 0;
        g.blinkOn = !g.blinkOn;
    }
    const bool turnSoon = g.navDistance < 120 && kRoute[g.navStep].maneuver != evb::link::Maneuver::Straight;
    const bool rightTurn = kRoute[g.navStep].maneuver == evb::link::Maneuver::Right
        || kRoute[g.navStep].maneuver == evb::link::Maneuver::SlightRight;

    evb::CanFrame vcu = makeFrame(evb::canid::VcuStatus, 4);
    evb::canSetBitsLE(vcu.data, 0, 16, static_cast<uint32_t>(g.speedX10));
    evb::canSetBitsLE(vcu.data, 16, 3, sc == SportRun ? 2u : 0u);
    evb::canSetBitsLE(vcu.data, 19, 2, g.timeMs < kBootParkedMs ? 0u : 3u);
    evb::canSetBitsLE(vcu.data, 21, 1, 1u);
    const bool standDown = g.speedX10 == 0 && !parked.value() && (g.timeMs < kBootStandDownMs || phase < 3);
    evb::canSetBitsLE(vcu.data, 22, 1, standDown ? 1u : 0u);
    evb::canSetBitsLE(vcu.data, 23, 1, sc == Crash ? 1u : 0u);
    evb::canSetBitsLE(vcu.data, 24, 8, 27u + 40u);
    Backend::postCanFrame(vcu);

    evb::CanFrame motor = makeFrame(evb::canid::MotorStatus, 6);
    evb::canSetBitsLE(motor.data, 0, 16, static_cast<uint32_t>(rpm));
    evb::canSetBitsLE(motor.data, 16, 16, static_cast<uint32_t>(currentX10) & 0xFFFFu);
    evb::canSetBitsLE(motor.data, 32, 8, static_cast<uint32_t>(g.motorTemp + 40));
    evb::canSetBitsLE(motor.data, 40, 8, static_cast<uint32_t>(g.motorTemp - 8 + 40));
    Backend::postCanFrame(motor);

    evb::CanFrame bms = makeFrame(evb::canid::BmsStatus, 8);
    evb::canSetBitsLE(bms.data, 0, 10, static_cast<uint32_t>(g.socX10));
    evb::canSetBitsLE(bms.data, 16, 16, 712u);
    evb::canSetBitsLE(bms.data, 32, 16, static_cast<uint32_t>(currentX10 / 3) & 0xFFFFu);
    evb::canSetBitsLE(bms.data, 48, 8, static_cast<uint32_t>(g.packTemp + 40));
    Backend::postCanFrame(bms);

    evb::CanFrame range = makeFrame(evb::canid::BmsRange, 2);
    evb::canSetBitsLE(range.data, 0, 16, static_cast<uint32_t>(g.socX10 * 12 / 100));
    Backend::postCanFrame(range);

    evb::CanFrame lamps = makeFrame(evb::canid::BodyLamps, 1);
    evb::canSetBitsLE(lamps.data, 0, 1, (turnSoon && !rightTurn && g.blinkOn) ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 1, 1, (turnSoon && rightTurn && g.blinkOn) ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 2, 1, sc == SportRun ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 3, 1, 1u);
    Backend::postCanFrame(lamps);

    evb::CanFrame abs = makeFrame(evb::canid::AbsStatus, 1);
    Backend::postCanFrame(abs);

    evb::CanFrame tpms = makeFrame(evb::canid::Tpms, 4);
    evb::canSetBitsLE(tpms.data, 0, 16, 320u);
    evb::canSetBitsLE(tpms.data, 16, 16, static_cast<uint32_t>(g.rearPsiX10));
    Backend::postCanFrame(tpms);

    evb::CanFrame odo = makeFrame(evb::canid::Odometer, 8);
    evb::canSetBitsLE(odo.data, 0, 32, g.odoX10);
    evb::canSetBitsLE(odo.data, 32, 32, g.tripX10);
    Backend::postCanFrame(odo);

    g.navDistance -= g.speedX10 * elapsedMs / 36000;
    if (g.navDistance <= 0) {
        g.navStep = (g.navStep + 1) % kRouteLen;
        g.navDistance = kRoute[g.navStep].distance;
    }

    g.phoneTimerMs += elapsedMs;
    if (g.phoneTimerMs >= 1000) {
        g.phoneTimerMs = 0;
        sendPhoneTraffic(sc);
    }
}
