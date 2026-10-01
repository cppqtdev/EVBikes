#include "TripData.h"

#include "VehicleData.h"

namespace {
// A gap longer than this means the cluster was not running, not that the rider
// sat still for it.
constexpr uint32_t kMaxStepMs = 2000;
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
    const int trip = vehicle.tripKmX10.value();
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
    const int mode = vehicle.rideMode.value();
    if (mode >= 0 && mode < 3)
        m_modeMs[mode] += step;

    publish();
}

void TripData::publish()
{
    rideMinutes.setValue(static_cast<int>(m_movingMs / 60000));
    recorded.setValue(m_movingMs > 0);

    if (m_startSoc >= 0) {
        const int used = m_startSoc - VehicleData::instance().batteryPercent.value();
        socUsedPercent.setValue(used > 0 ? used : 0);
    }

    if (m_movingMs == 0) {
        ecoShare.setValue(0);
        normalShare.setValue(0);
        sportShare.setValue(0);
        return;
    }

    // Two shares are rounded and the third takes the remainder, so the three
    // always add up to the 100 per cent the ring is drawn from.
    const int eco = static_cast<int>((m_modeMs[0] * 100 + m_movingMs / 2) / m_movingMs);
    const int normal = static_cast<int>((m_modeMs[1] * 100 + m_movingMs / 2) / m_movingMs);
    const int sport = 100 - eco - normal;
    ecoShare.setValue(eco);
    normalShare.setValue(normal);
    sportShare.setValue(sport < 0 ? 0 : sport);
}
