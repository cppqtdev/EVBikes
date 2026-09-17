#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>

// What the current ride adds up to. The distance itself comes over the bus as
// the bike's own trip counter; everything here is measured alongside it, from
// power-up or from the moment the rider zeroes that counter.
struct TripData : public Qul::Singleton<TripData>
{
    Qul::Property<int> rideMinutes;
    Qul::Property<int> socUsedPercent;

    // Share of the moving time spent in each mode, as whole per cent summing
    // to 100 once the bike has moved at all.
    Qul::Property<int> ecoShare;
    Qul::Property<int> normalShare;
    Qul::Property<int> sportShare;

    // False until the bike has moved, so a screen can say so rather than show
    // a row of confident zeroes.
    Qul::Property<bool> recorded;

    TripData();

    void reset();
    // Takes the clock from the caller so a test can drive it. The generated
    // desktop bridge skips it: uint32_t is not a type QML can pass.
    void update(uint32_t nowMs);

private:
    void publish();

    uint32_t m_lastMs = 0;
    uint32_t m_movingMs = 0;
    uint32_t m_modeMs[3] = {0, 0, 0};
    int m_lastTripKmX10 = 0;
    int m_startSoc = -1;
};
