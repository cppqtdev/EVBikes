#include "AlertData.h"
#include "ClusterInput.h"
#include "NavigationData.h"
#include "PhoneData.h"
#include "Simulator.h"
#include "SystemData.h"
#include "VehicleData.h"
#include "../src/backend/Backend.h"

#include <cstdio>

static int g_failures = 0;
#define CHECK(cond) do { if (!(cond)) { std::printf("FAIL %s:%d %s\n", __FILE__, __LINE__, #cond); ++g_failures; } } while (0)

static void run(Simulator &sim, int ms)
{
    for (int t = 0; t < ms; t += 50) {
        sim.step(50);
        if (t % 1000 == 0)
            SystemData::instance().tick();
    }
}

int main()
{
    Backend::init();
    Simulator &sim = Simulator::instance();

    run(sim, 15000);
    const VehicleData &v = VehicleData::instance();
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

    std::printf(g_failures ? "%d FAILURE(S)\n" : "BACKEND SMOKE PASSED\n", g_failures);
    return g_failures ? 1 : 0;
}
