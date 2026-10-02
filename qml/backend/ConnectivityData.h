#pragma once
#include <qul/property.h>
#include <qul/singleton.h>
#include <cstdint>

// Pairing simulation is explicit. Hardware availability is supplied by the
// platform, not inferred from Qt modules or from a phone-status packet.
struct ConnectivityData : public Qul::Singleton<ConnectivityData>
{
    enum State : uint8_t { Unavailable = 0, Disconnected, Pairing, Connected };
    Qul::Property<bool> simulated;
    Qul::Property<bool> bluetoothAvailable;
    Qul::Property<bool> wifiAvailable;
    Qul::Property<uint8_t> bluetoothState;
    ConnectivityData();
    void pair();
    void disconnect();
    void advance(uint32_t elapsedMs);
private:
    uint16_t m_pairRemainingMs = 0;
};
