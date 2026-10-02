#include "Simulator.h"

#include "Backend.h"
#include "ConnectivityData.h"
#include "SystemData.h"
#include "../core/can/CanIds.h"
#include "../core/simulation/DistanceIntegrator.h"
#include "../platform/PlatformIo.h"

#include <cstdio>

#include <cstring>

namespace {

enum Scenario : uint8_t { CityEco = 0, SportRun, LowTyre, Overheat, Crash, LampTest, PetrolDemo, ScenarioCount };

constexpr uint32_t kMaxTickMs = 100;
constexpr uint32_t kBootStandDownMs = 11000;
constexpr uint32_t kBootParkedMs = 14000;

struct SimState
{
    uint32_t timeMs = 0;
    uint16_t speedX10 = 0;
    uint16_t targetSpeedX10 = 450;
    uint16_t socX10 = 820;
    uint8_t packTemp = 34;
    uint8_t motorTemp = 48;
    uint16_t rearPsiX10 = 320;
    uint32_t odoX10 = 123560;
    uint32_t tripX10 = 90;
    uint16_t navDistance = 180;
    uint16_t tripRemainderM = 0;
    uint16_t accelerationRemainder = 0;
    uint32_t energyMwh = 3280000;
    evb::DistanceIntegrator distance;
    uint8_t navStep = 0;
    uint8_t rideMode = 0;
    uint16_t phoneTimerMs = 0;
    uint16_t blinkMs = 0;
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

template <typename T, typename U, typename V>
void approach(T &value, U targetValue, V stepValue)
{
    const T target = static_cast<T>(targetValue);
    const T step = static_cast<T>(stepValue);
    if (value < target) value = (target - value < step) ? target : static_cast<T>(value + step);
    else if (value > target) value = (value - target < step) ? target : static_cast<T>(value - step);
}

struct NavStep
{
    evb::link::Maneuver maneuver;
    uint16_t distance;
    const char *road;
};

constexpr NavStep kRoute[] = {
    {evb::link::Maneuver::Right, 180, "MG Road"},
    {evb::link::Maneuver::Straight, 300, "Outer Ring Road"},
    {evb::link::Maneuver::RoundaboutEnter, 180, "Silk Board Junction"},
    {evb::link::Maneuver::SlightLeft, 140, "Hosur Road"},
    {evb::link::Maneuver::Left, 160, "Electronic City Phase 1"},
    {evb::link::Maneuver::Destination, 150, "Office"},
};
constexpr uint8_t kRouteLen = sizeof(kRoute) / sizeof(kRoute[0]);

void sendPhoneTraffic()
{
    uint8_t frame[evb::link::kMaxFrame];

    evb::link::NavUpdate nav;
    const NavStep &step = kRoute[g.navStep];
    nav.maneuver = step.maneuver;
    nav.roundaboutExit = step.maneuver == evb::link::Maneuver::RoundaboutEnter ? 2 : 0;
    nav.distanceToManeuverM = static_cast<uint32_t>(g.navDistance);
    uint32_t remaining = static_cast<uint32_t>(g.navDistance);
    for (uint8_t i = static_cast<uint8_t>(g.navStep + 1); i < kRouteLen; ++i)
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
    const uint16_t pos = static_cast<uint16_t>((g.timeMs / 1000) % 233);
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

}

// The phone owns these lists; the simulator stands in for it so the rows have
// something to draw before a real handset is paired.
void sendListsOnce()
{
    static bool sent = false;
    if (ConnectivityData::instance().bluetoothState.value() != ConnectivityData::Connected) {
        sent = false;
        return;
    }
    if (sent)
        return;
    sent = true;

    struct Row
    {
        evb::link::ListId list;
        const char *title;
        const char *text;
    };
    static const Row kRows[] = {
        {evb::link::ListId::Contacts, "Karan", "Reached the office, see you soon"},
        {evb::link::ListId::Contacts, "Akash", "Lunch at 1?"},
        {evb::link::ListId::Contacts, "Myra", "Call me when you are free"},
        {evb::link::ListId::Reminders, "Service due", "In 240 km"},
        {evb::link::ListId::Reminders, "Insurance renewal", "12 November"},
        {evb::link::ListId::Reminders, "Tyre check", "Every 15 days"},
    };

    uint8_t frame[evb::link::kMaxFrame];
    uint8_t slot[2] = {0, 0};
    for (const Row &row : kRows) {
        evb::link::ListEntry entry;
        entry.list = row.list;
        const uint8_t which = static_cast<uint8_t>(row.list);
        entry.slot = slot[which]++;
        std::strncpy(entry.title, row.title, evb::link::kMaxText);
        std::strncpy(entry.text, row.text, evb::link::kMaxText);
        const std::size_t n = evb::link::encodeListEntry(entry, frame, sizeof(frame));
        Backend::postPhoneBytes(frame, n);
    }
}

void sendTimeSyncOnce()
{
    static bool sent = false;
    if (ConnectivityData::instance().bluetoothState.value() != ConnectivityData::Connected) {
        sent = false;
        return;
    }
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
    running.setValue(evb::platform::isSimulator());
    scenario.setValue(CityEco);
    parked.setValue(false);
}

void Simulator::start()
{
    if (m_started)
        return;
    m_started = true;
    m_lastTickMs = evb::platform::millis();
    m_timer.setSingleShot(false);
    m_timer.onTimeout([this]() { onRuntimeTick(); });
    m_timer.start(50);
}

void Simulator::stop()
{
    m_timer.stop();
    m_started = false;
}

void Simulator::onRuntimeTick()
{
    const uint32_t nowMs = evb::platform::millis();
    //  A long gap -- the resources loading before the first frame, or a slow
    //  frame later -- is not time the rider saw. Counting it would run the
    //  boot animation to its end in one step and the splash would never
    //  appear, so a tick is worth at most one frame of it.
    const uint32_t gapMs = nowMs - m_lastTickMs;
    const uint32_t elapsedMs = gapMs > kMaxTickMs ? kMaxTickMs : gapMs;
    m_lastTickMs = nowMs;
    if (elapsedMs == 0)
        return;

    if (running.value())
        step(elapsedMs);

    SystemData::instance().advanceRuntime(elapsedMs);
    ConnectivityData::instance().advance(elapsedMs);

    m_pollElapsedMs += elapsedMs;
    if (m_pollElapsedMs >= 100) {
        m_pollElapsedMs %= 100;
        //  Read the clock again rather than reusing nowMs from the top of the
        //  tick: step() has run since, and it stamps each frame with the time
        //  it was made. The timeout check subtracts without sign, so a stamp
        //  one millisecond ahead of the time it is compared against wraps to
        //  four billion and every node is declared dead at once.
        Backend::periodic(evb::platform::millis());
    }
    m_clockElapsedMs += elapsedMs;
    if (m_clockElapsedMs >= 1000) {
        m_clockElapsedMs %= 1000;
        SystemData::instance().tick();
    }

    static uint32_t lastDiagnosticMs = 0;
    const uint32_t diagnosticNowMs = evb::platform::millis();
    if (evb::platform::isSimulator() && diagnosticNowMs - lastDiagnosticMs >= 1000) {
        lastDiagnosticMs = diagnosticNowMs;
        std::printf("[sim] t=%lu ms speed=%u.%u km/h target=%u.%u scenario=%u parked=%u standDown=%u\n",
                    static_cast<unsigned long>(g.timeMs),
                    static_cast<unsigned>(g.speedX10 / 10), static_cast<unsigned>(g.speedX10 % 10),
                    static_cast<unsigned>(g.targetSpeedX10 / 10), static_cast<unsigned>(g.targetSpeedX10 % 10),
                    static_cast<unsigned>(scenario.value()), parked.value() ? 1u : 0u,
                    (g.speedX10 == 0 && !parked.value() && g.timeMs < kBootStandDownMs) ? 1u : 0u);
        std::fflush(stdout);
    }
}

void Simulator::togglePark()
{
    parked.setValue(!parked.value());
}

void Simulator::cycleRideMode()
{
    if (running.value())
        g.rideMode = static_cast<uint8_t>((g.rideMode + 1u) % 3u);
}

void Simulator::nextScenario()
{
    const uint8_t next = static_cast<uint8_t>((scenario.value() + 1) % ScenarioCount);
    scenario.setValue(next);
    g.rideMode = next == SportRun ? 2u : 0u;
    g.rearPsiX10 = 320;
    g.packTemp = 34;
    g.motorTemp = 48;
}

void Simulator::step(uint32_t elapsedMs)
{
    if (!running.value() || elapsedMs == 0)
        return;
    if (elapsedMs > kMaxTickMs)
        elapsedMs = kMaxTickMs;

    const uint8_t sc = scenario.value();
    g.timeMs += elapsedMs;
    sendTimeSyncOnce();
    sendListsOnce();

    // Repeatable stop/start city ride, with a separate faster sport scenario.
    const uint8_t phase = static_cast<uint8_t>((g.timeMs / 1000) % 90);
    if (sc == Crash || parked.value() || g.timeMs < kBootParkedMs)
        g.targetSpeedX10 = 0;
    else if (phase < 30)
        g.targetSpeedX10 = sc == SportRun ? 1120 : 520;
    else if (phase < 40)
        g.targetSpeedX10 = 180;
    else if (phase < 55)
        g.targetSpeedX10 = sc == SportRun ? 1250 : 680;
    else if (phase < 68)
        g.targetSpeedX10 = 0;
    else
        g.targetSpeedX10 = sc == SportRun ? 960 : 420;
    const uint16_t rate = g.targetSpeedX10 < g.speedX10 ? 180 : (sc == SportRun ? 180 : 100);
    const uint32_t speedDelta = rate * elapsedMs + g.accelerationRemainder;
    const uint16_t speedStep = static_cast<uint16_t>(speedDelta / 1000u);
    g.accelerationRemainder = static_cast<uint16_t>(speedDelta % 1000u);
    approach(g.speedX10, g.targetSpeedX10, speedStep);

    const int32_t accel = static_cast<int32_t>(g.targetSpeedX10) - static_cast<int32_t>(g.speedX10);
    const int16_t currentX10 = static_cast<int16_t>(g.speedX10 == 0 ? 0 : (accel > 0 ? 900 + accel * 8 : (accel < 0 ? -300 : 350)));
    const uint16_t rpm = static_cast<uint16_t>(g.speedX10 * 9u);

    const uint32_t travelledM = g.distance.advance(g.speedX10, elapsedMs);
    const uint32_t tripMetres = g.tripRemainderM + travelledM;
    g.odoX10 += tripMetres / 100u;
    g.tripX10 += tripMetres / 100u;
    g.tripRemainderM = static_cast<uint16_t>(tripMetres % 100u);
    // Demo pack: 4 kWh, nominal city consumption 34 Wh/km. Range and SOC
    // originate in simulated BMS frames, never from a UI animation.
    const uint32_t usedMwh = travelledM * (sc == SportRun ? 48u : 34u);
    g.energyMwh = usedMwh < g.energyMwh ? g.energyMwh - usedMwh : 0;
    g.socX10 = static_cast<uint16_t>(g.energyMwh / 4000u);

    if (sc == LowTyre) approach(g.rearPsiX10, 265, 1);
    if (sc == Overheat) { approach(g.packTemp, 62, 1); approach(g.motorTemp, 118, 1); }

    g.blinkMs += elapsedMs;
    if (g.blinkMs >= 400) {
        g.blinkMs = 0;
        g.blinkOn = !g.blinkOn;
    }
    const bool leftTurn = kRoute[g.navStep].maneuver == evb::link::Maneuver::Left
        || kRoute[g.navStep].maneuver == evb::link::Maneuver::SlightLeft;
    const bool turnSoon = g.navDistance < 120;
    const bool rightTurn = kRoute[g.navStep].maneuver == evb::link::Maneuver::Right
        || kRoute[g.navStep].maneuver == evb::link::Maneuver::SlightRight;

    evb::CanFrame vcu = makeFrame(evb::canid::VcuStatus, 4);
    evb::canSetBitsLE(vcu.data, 0, 16, static_cast<uint32_t>(g.speedX10));
    evb::canSetBitsLE(vcu.data, 16, 3, g.rideMode);
    evb::canSetBitsLE(vcu.data, 19, 2, (parked.value() || g.timeMs < kBootParkedMs) ? 0u : 3u);
    evb::canSetBitsLE(vcu.data, 21, 1, 1u);
    const bool standDown = g.speedX10 == 0 && !parked.value() && g.timeMs < kBootStandDownMs;
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

    evb::CanFrame powertrain = makeFrame(evb::canid::PowertrainStatus, 4);
    powertrain.data[0] = sc == PetrolDemo ? 1u : 0u;
    powertrain.data[1] = sc == PetrolDemo && phase % 30 > 20 ? 8u : 65u;
    uint16_t warnings = 0;
    if (sc == PetrolDemo)
        warnings = static_cast<uint16_t>(1u << ((phase / 4u) % 6u));
    else if (sc == LampTest)
        warnings = static_cast<uint16_t>(1u << (5u + ((phase / 4u) % 11u)));
    if (sc == Overheat) warnings |= (1u << 7) | (1u << 8);
    evb::canSetBitsLE(powertrain.data, 16, 16, warnings);
    Backend::postCanFrame(powertrain);

    evb::CanFrame bms = makeFrame(evb::canid::BmsStatus, 8);
    evb::canSetBitsLE(bms.data, 0, 10, static_cast<uint32_t>(g.socX10));
    evb::canSetBitsLE(bms.data, 16, 16, 712u);
    evb::canSetBitsLE(bms.data, 32, 16, static_cast<uint32_t>(currentX10 / 3) & 0xFFFFu);
    evb::canSetBitsLE(bms.data, 48, 8, static_cast<uint32_t>(g.packTemp + 40));
    Backend::postCanFrame(bms);

    evb::CanFrame range = makeFrame(evb::canid::BmsRange, 2);
    evb::canSetBitsLE(range.data, 0, 16, static_cast<uint32_t>(g.energyMwh / (sc == SportRun ? 48000u : 34000u)));
    Backend::postCanFrame(range);

    evb::CanFrame lamps = makeFrame(evb::canid::BodyLamps, 1);
    evb::canSetBitsLE(lamps.data, 0, 1, ((turnSoon && leftTurn) || (sc == LampTest && phase % 12 < 4)) && g.blinkOn ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 1, 1, ((turnSoon && rightTurn) || (sc == LampTest && phase % 12 >= 4 && phase % 12 < 8)) && g.blinkOn ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 2, 1, sc == SportRun ? 1u : 0u);
    evb::canSetBitsLE(lamps.data, 3, 1, 1u);
    evb::canSetBitsLE(lamps.data, 4, 1, sc == LampTest && phase % 12 >= 8 && g.blinkOn ? 1u : 0u);
    Backend::postCanFrame(lamps);

    evb::CanFrame abs = makeFrame(evb::canid::AbsStatus, 1);
    evb::canSetBitsLE(abs.data, 0, 1, sc == LampTest && phase % 20 < 4 ? 1u : 0u);
    evb::canSetBitsLE(abs.data, 1, 1, accel < -200 && g.speedX10 > 100 ? 1u : 0u);
    Backend::postCanFrame(abs);

    evb::CanFrame tpms = makeFrame(evb::canid::Tpms, 4);
    evb::canSetBitsLE(tpms.data, 0, 16, 320u);
    evb::canSetBitsLE(tpms.data, 16, 16, static_cast<uint32_t>(g.rearPsiX10));
    Backend::postCanFrame(tpms);

    evb::CanFrame odo = makeFrame(evb::canid::Odometer, 8);
    evb::canSetBitsLE(odo.data, 0, 32, g.odoX10);
    evb::canSetBitsLE(odo.data, 32, 32, g.tripX10);
    Backend::postCanFrame(odo);

    uint32_t remainingM = travelledM;
    // Bounded route walk retains overshoot and never wraps past the array.
    for (uint8_t n = 0; n < kRouteLen && remainingM >= g.navDistance; ++n) {
        remainingM -= g.navDistance;
        g.navStep = static_cast<uint8_t>((g.navStep + 1u) % kRouteLen);
        g.navDistance = kRoute[g.navStep].distance;
    }
    g.navDistance = remainingM < g.navDistance
        ? static_cast<uint16_t>(g.navDistance - remainingM) : 1u;

    g.phoneTimerMs += elapsedMs;
    if (g.phoneTimerMs >= 1000) {
        g.phoneTimerMs = 0;
        sendPhoneTraffic();
    }
}
