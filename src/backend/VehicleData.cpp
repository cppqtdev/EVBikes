#include "VehicleData.h"

#include "../core/can/VehicleSignals.h"

namespace {
constexpr int kMaxPhaseCurrentAx10 = 2500;
}

VehicleData::VehicleData()
{
    batteryPercent.setValue(100);
    ambientTempC.setValue(25);
    packTempC.setValue(25);
    motorTempC.setValue(25);
    controllerTempC.setValue(25);
    tyreFrontPsiX10.setValue(320);
    tyreRearPsiX10.setValue(320);
    lowBeam.setValue(true);
    driveState.setValue(Park);
    driveStale.setValue(true);
    batteryStale.setValue(true);
    lampsStale.setValue(true);
}

void VehicleData::applySignal(int signalId, int value)
{
    using evb::SignalId;
    switch (static_cast<SignalId>(signalId)) {
    case SignalId::SpeedKmhX10: speedKmh.setValue((value + 5) / 10); break;
    case SignalId::MotorRpm: motorRpm.setValue(value); break;
    case SignalId::PhaseCurrentAx10: {
        int pct = value * 100 / kMaxPhaseCurrentAx10;
        pct = pct > 100 ? 100 : (pct < -100 ? -100 : pct);
        powerPercent.setValue(pct);
        break;
    }
    case SignalId::RideMode: rideMode.setValue(value); break;
    case SignalId::DriveState: driveState.setValue(value); break;
    case SignalId::ReadyToRide: readyToRide.setValue(value != 0); break;
    case SignalId::SideStandDown: sideStandDown.setValue(value != 0); break;
    case SignalId::SocPercentX10: batteryPercent.setValue((value + 5) / 10); break;
    case SignalId::PackVoltageX10: packVoltageX10.setValue(value); break;
    case SignalId::PackCurrentAx10: packCurrentAx10.setValue(value); break;
    case SignalId::PackTempC: packTempC.setValue(value); break;
    case SignalId::MotorTempC: motorTempC.setValue(value); break;
    case SignalId::ControllerTempC: controllerTempC.setValue(value); break;
    case SignalId::ChargingState: chargeState.setValue(value); break;
    case SignalId::RangeKm: rangeKm.setValue(value); break;
    case SignalId::IndicatorLeft: indicatorLeft.setValue(value != 0); break;
    case SignalId::IndicatorRight: indicatorRight.setValue(value != 0); break;
    case SignalId::HighBeam: highBeam.setValue(value != 0); break;
    case SignalId::LowBeam: lowBeam.setValue(value != 0); break;
    case SignalId::Hazard: hazard.setValue(value != 0); break;
    case SignalId::AbsFault: absFault.setValue(value != 0); break;
    case SignalId::AbsActive: absActive.setValue(value != 0); break;
    case SignalId::TyreFrontPsiX10: tyreFrontPsiX10.setValue(value); break;
    case SignalId::TyreRearPsiX10: tyreRearPsiX10.setValue(value); break;
    case SignalId::OdometerKmX10: odometerKm.setValue(value / 10); break;
    case SignalId::TripAKmX10: tripKmX10.setValue(value); break;
    case SignalId::FaultCode: faultCode.setValue(value); break;
    case SignalId::CrashDetected: crashDetected.setValue(value != 0); break;
    case SignalId::AmbientTempC: ambientTempC.setValue(value); break;
    default: break;
    }
}
