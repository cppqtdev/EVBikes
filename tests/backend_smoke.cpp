#include "AlertData.h"
#include "ClusterInput.h"
#include "NavigationData.h"
#include "PhoneData.h"
#include "PhoneListData.h"
#include "Simulator.h"
#include "SystemData.h"
#include "TripData.h"
#include "VehicleData.h"
#include "../src/backend/Backend.h"
#include "../src/core/can/VehicleCanDecoder.h"

#include <chrono>
#include <cstdio>
#include <thread>

static int g_failures = 0;
#define CHECK(cond) do { if (!(cond)) { std::printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #cond); ++g_failures; } } while (0)

static void run(Simulator &sim, int ms)
{
    for (int t = 0; t < ms; t += 50) {
        sim.step(50);
        SystemData::instance().poll();
        if (t % 1000 == 0)
            SystemData::instance().tick();
    }
}

int main()
{
    Backend::init();
    Simulator &sim = Simulator::instance();

    const VehicleData &v = VehicleData::instance();
    CHECK(v.driveStale.value());
    CHECK(v.batteryStale.value());

    run(sim, 15000);
    CHECK(!v.driveStale.value());
    CHECK(!v.batteryStale.value());
    CHECK(v.speedKmh.value() > 0);
    CHECK(v.motorRpm.value() > 0);
    CHECK(v.readyToRide.value());
    CHECK(v.batteryPercent.value() > 0 && v.batteryPercent.value() <= 100);
    CHECK(v.rangeKm.value() > 0);
    CHECK(v.ambientTempC.value() == 27);
    CHECK(v.faultCode.value() == 0);
    CHECK(NavigationData::instance().active.value());
    CHECK(!NavigationData::instance().roadName.value().empty());
    CHECK(PhoneData::instance().connected.value());
    CHECK(PhoneData::instance().trackTitle.value() == "Dandelions");
    CHECK(PhoneListData::instance().contactCount.value() == 3);
    CHECK(PhoneListData::instance().reminderCount.value() == 3);
    CHECK(PhoneListData::instance().contact0Name.value() == "Karan");
    CHECK(PhoneListData::instance().contact0Initial.value() == "K");
    CHECK(PhoneListData::instance().reminder2Name.value() == "Tyre check");

    CHECK(SystemData::instance().clockValid.value());
    CHECK(AlertData::instance().kind.value() == AlertData::NoAlert);

    sim.nextScenario();
    run(sim, 30000);
    CHECK(v.rideMode.value() == VehicleData::Sport);
    CHECK(v.highBeam.value());

    sim.nextScenario();
    run(sim, 20000);
    CHECK(v.tyreRearPsiX10.value() < 280);
    CHECK(AlertData::instance().kind.value() == AlertData::LowTyreRear);
    CHECK(AlertData::instance().popupVisible.value());
    AlertData::instance().acknowledge();
    CHECK(!AlertData::instance().popupVisible.value());

    sim.nextScenario();
    run(sim, 40000);
    CHECK(AlertData::instance().kind.value() == AlertData::BatteryOverheat);
    CHECK(AlertData::instance().level.value() == AlertData::LevelCritical);
    AlertData::instance().acknowledge();
    CHECK(AlertData::instance().popupVisible.value());

    sim.nextScenario();
    run(sim, 2000);
    CHECK(AlertData::instance().kind.value() == AlertData::CrashDetected);
    run(sim, 3000);
    CHECK(AlertData::instance().phase.value() == 1);
    CHECK(AlertData::instance().sosSecondsLeft.value() < 60);
    AlertData::instance().cancelSos();
    CHECK(!AlertData::instance().popupVisible.value());
    run(sim, 2000);
    CHECK(!AlertData::instance().popupVisible.value());

    SystemData &sys = SystemData::instance();
    CHECK(sys.locked.value());
    sys.selectProfile(2);
    sys.startScan();
    sys.completeScan();
    CHECK(sys.authState.value() == SystemData::AuthDenied);
    sys.selectProfile(1);
    sys.startScan();
    sys.completeScan();
    CHECK(sys.authState.value() == SystemData::AuthMatched);
    CHECK(!sys.locked.value());
    sys.locked.setValue(true);
    CHECK(!sys.submitPin(1111));
    CHECK(sys.pinAttemptsLeft.value() == 2);
    CHECK(sys.submitPin(1234));
    CHECK(!sys.locked.value());

    int gotButton = -1;
    ClusterInput::instance().buttonEvent.connect([&](int b, int) { gotButton = b; });
    ClusterInput::instance().inject(ClusterInput::Ok, ClusterInput::Press);
    CHECK(gotButton == ClusterInput::Ok);

    PhoneData::instance().mediaNext();

    // The run above packs fifteen simulated seconds into no real time at all,
    // and the trip recorder measures against the clock, so give it one.
    TripData &trip = TripData::instance();
    trip.reset();
    VehicleData &vehicle = VehicleData::instance();
    vehicle.speedKmh.setValue(40);
    vehicle.batteryPercent.setValue(80);
    vehicle.rideMode.setValue(VehicleData::Eco);
    uint32_t clock = 100000;
    // The first call after a gap only sets the mark; time is measured from
    // there, which is why the loop is primed.
    trip.update(clock);
    for (int i = 0; i < 360; ++i) {
        if (i == 240)
            vehicle.rideMode.setValue(VehicleData::Sport);
        if (i == 350)
            vehicle.batteryPercent.setValue(71);
        clock += 1000;
        trip.update(clock);
    }
    CHECK(trip.recorded.value());
    CHECK(trip.rideMinutes.value() == 6);
    CHECK(trip.ecoShare.value() == 67);
    CHECK(trip.sportShare.value() == 33);
    CHECK(trip.ecoShare.value() + trip.normalShare.value() + trip.sportShare.value() == 100);
    CHECK(trip.socUsedPercent.value() == 9);

    // Standing still adds nothing.
    vehicle.speedKmh.setValue(0);
    trip.update(clock + 2000);
    CHECK(trip.rideMinutes.value() == 6);

    // Let the bus fall silent for longer than the node timeout: the readings
    // must be marked stale, and come back when the frames do.
    std::this_thread::sleep_for(std::chrono::milliseconds(evb::VehicleCanDecoder::kTimeoutMs + 150));
    SystemData::instance().poll();
    CHECK(v.driveStale.value());
    CHECK(v.batteryStale.value());
    run(sim, 500);
    CHECK(!v.driveStale.value());
    CHECK(!v.batteryStale.value());

    std::printf(g_failures ? "%d FAILURE(S)\n" : "BACKEND SMOKE PASSED\n", g_failures);
    return g_failures ? 1 : 0;
}
