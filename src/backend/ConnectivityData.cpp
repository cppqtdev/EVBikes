#include "ConnectivityData.h"
#include "NavigationData.h"
#include "PhoneData.h"
#include "PhoneListData.h"
#include "VehicleData.h"
#include "../platform/PlatformIo.h"

ConnectivityData::ConnectivityData()
{
    const bool demo = evb::platform::isSimulator();
    simulated.setValue(demo);
    bluetoothAvailable.setValue(demo);
    wifiAvailable.setValue(false);
    bluetoothState.setValue(demo ? Connected : Unavailable);
}

void ConnectivityData::pair()
{
    const auto &vehicle = VehicleData::instance();
    if (!simulated.value() || vehicle.driveStale.value() || vehicle.speedKmh.value() != 0
        || bluetoothState.value() == Connected || bluetoothState.value() == Pairing)
        return;
    m_pairRemainingMs = 2000;
    bluetoothState.setValue(Pairing);
}

void ConnectivityData::disconnect()
{
    if (!simulated.value() || VehicleData::instance().driveStale.value()
        || VehicleData::instance().speedKmh.value() != 0)
        return;
    m_pairRemainingMs = 0;
    bluetoothState.setValue(Disconnected);
    PhoneData::instance().connected.setValue(false);
    PhoneData::instance().callStatus.setValue(PhoneData::Idle);
    PhoneData::instance().mediaPlaying.setValue(false);
    NavigationData::instance().clear();
    PhoneListData::instance().clear();
}

void ConnectivityData::advance(uint32_t elapsedMs)
{
    if (bluetoothState.value() != Pairing)
        return;
    m_pairRemainingMs = elapsedMs >= m_pairRemainingMs ? 0
        : static_cast<uint16_t>(m_pairRemainingMs - elapsedMs);
    if (m_pairRemainingMs == 0)
        bluetoothState.setValue(Connected);
}
