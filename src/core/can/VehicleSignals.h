#pragma once

#include <cstdint>

namespace evb {

// One entry per value the UI can show. Values are scaled integers (see docs/03-protocols.md).
enum class SignalId : uint8_t {
    SpeedKmhX10,
    MotorRpm,
    PhaseCurrentAx10,
    RideMode,
    DriveState,
    ReadyToRide,
    SideStandDown,
    SocPercentX10,
    PackVoltageX10,
    PackCurrentAx10,
    PackTempC,
    MotorTempC,
    ControllerTempC,
    ChargingState,
    RangeKm,
    IndicatorLeft,
    IndicatorRight,
    HighBeam,
    LowBeam,
    Hazard,
    AbsFault,
    AbsActive,
    TyreFrontPsiX10,
    TyreRearPsiX10,
    OdometerKmX10,
    TripAKmX10,
    FaultCode,
    CrashDetected,
    AmbientTempC,
    Count
};

struct VehicleSignal
{
    SignalId id = SignalId::Count;
    int32_t value = 0;
};

} // namespace evb
