#include "TripData.h"

#include "VehicleData.h"

namespace {
// A gap longer than this means the cluster was not running, not that the rider
// sat still for it.
constexpr uint32_t kMaxStepMs = 2000;

template <typename T>
void setIfChanged(Qul::Property<T> &property, T value)
{
    if (property.value() != value)
        property.setValue(value);
}
}

TripData::TripData()
{
    reset();
}

void TripData::reset()
{
    m_movingMs = 0;
    m_modeMs[0] = 0;
    m_modeMs[1] = 0;
    m_modeMs[2] = 0;
    m_startSoc = -1;
    rideMinutes.setValue(0);
    socUsedPercent.setValue(0);
    ecoShare.setValue(0);
    normalShare.setValue(0);
    sportShare.setValue(0);
    recorded.setValue(false);
}

void TripData::update(uint32_t nowMs)
{
    VehicleData &vehicle = VehicleData::instance();

    // The rider zeroing the bike's trip counter starts a new ride here too.
    const uint32_t trip = vehicle.tripKmX10.value();
    if (trip < m_lastTripKmX10)
        reset();
    m_lastTripKmX10 = trip;

    const uint32_t step = nowMs - m_lastMs;
    m_lastMs = nowMs;
    if (step == 0 || step > kMaxStepMs)
        return;

    if (vehicle.speedKmh.value() <= 0) {
        publish();
        return;
    }

    if (m_startSoc < 0)
        m_startSoc = vehicle.batteryPercent.value();

    m_movingMs += step;
    const uint8_t mode = vehicle.rideMode.value();
    if (mode < 3)
        m_modeMs[mode] += step;

    publish();
}

void TripData::publish()
{
    setIfChanged(rideMinutes, static_cast<uint16_t>(m_movingMs / 60000));
    setIfChanged(recorded, m_movingMs > 0);

    if (m_startSoc >= 0) {
        const int16_t used = static_cast<int16_t>(m_startSoc - VehicleData::instance().batteryPercent.value());
        setIfChanged(socUsedPercent, static_cast<uint8_t>(used > 0 ? used : 0));
    }

    if (m_movingMs == 0) {
        setIfChanged(ecoShare, static_cast<uint8_t>(0));
        setIfChanged(normalShare, static_cast<uint8_t>(0));
        setIfChanged(sportShare, static_cast<uint8_t>(0));
        return;
    }

    // Two shares are rounded and the third takes the remainder, so the three
    // always add up to the 100 per cent the ring is drawn from.
    const uint8_t eco = static_cast<uint8_t>((m_modeMs[0] * 100 + m_movingMs / 2) / m_movingMs);
    const uint8_t normal = static_cast<uint8_t>((m_modeMs[1] * 100 + m_movingMs / 2) / m_movingMs);
    const int16_t sportPct = static_cast<int16_t>(100 - eco - normal);
    const uint8_t sport = static_cast<uint8_t>(sportPct < 0 ? 0 : sportPct);
    setIfChanged(ecoShare, eco);
    setIfChanged(normalShare, normal);
    setIfChanged(sportShare, sport);
}
