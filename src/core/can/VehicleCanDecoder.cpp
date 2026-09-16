#include "VehicleCanDecoder.h"
#include "CanIds.h"

namespace evb {

namespace {
constexpr std::size_t idx(SignalId id) { return static_cast<std::size_t>(id); }
}

void VehicleCanDecoder::emit(SignalId id, int32_t value)
{
    m_last[idx(id)] = value;
    m_known[idx(id)] = true;
    if (m_sink)
        m_sink(VehicleSignal{id, value}, m_ctx);
}

void VehicleCanDecoder::emitIfChanged(SignalId id, int32_t value)
{
    if (m_known[idx(id)] && m_last[idx(id)] == value)
        return;
    emit(id, value);
}

int32_t VehicleCanDecoder::timeoutFault(Node node)
{
    switch (node) {
    case Vcu: return 0x0101;
    case Motor: return 0x0102;
    case Bms: return 0x0201;
    default: return 0;
    }
}

void VehicleCanDecoder::markSeen(Node node, uint32_t timestampMs)
{
    m_lastSeen[node] = timestampMs;
    if (!m_timedOut[node])
        return;
    m_timedOut[node] = false;
    const int32_t code = timeoutFault(node);
    if (code != 0 && m_last[idx(SignalId::FaultCode)] == code)
        emit(SignalId::FaultCode, 0);
}

bool VehicleCanDecoder::decode(const CanFrame &f)
{
    const uint8_t *d = f.data;
    switch (f.id) {
    case canid::VcuStatus:
        if (f.dlc < 4) return false;
        markSeen(Vcu, f.timestampMs);
        emitIfChanged(SignalId::SpeedKmhX10, static_cast<int32_t>(canGetBitsLE(d, 0, 16)));
        emitIfChanged(SignalId::RideMode, static_cast<int32_t>(canGetBitsLE(d, 16, 3)));
        emitIfChanged(SignalId::DriveState, static_cast<int32_t>(canGetBitsLE(d, 19, 2)));
        emitIfChanged(SignalId::ReadyToRide, static_cast<int32_t>(canGetBitsLE(d, 21, 1)));
        emitIfChanged(SignalId::SideStandDown, static_cast<int32_t>(canGetBitsLE(d, 22, 1)));
        emitIfChanged(SignalId::CrashDetected, static_cast<int32_t>(canGetBitsLE(d, 23, 1)));
        emitIfChanged(SignalId::AmbientTempC, static_cast<int32_t>(canGetBitsLE(d, 24, 8)) - 40);
        return true;
    case canid::MotorStatus:
        if (f.dlc < 6) return false;
        markSeen(Motor, f.timestampMs);
        emitIfChanged(SignalId::MotorRpm, static_cast<int32_t>(canGetBitsLE(d, 0, 16)));
        emitIfChanged(SignalId::PhaseCurrentAx10, canGetSignedLE(d, 16, 16));
        emitIfChanged(SignalId::MotorTempC, static_cast<int32_t>(canGetBitsLE(d, 32, 8)) - 40);
        emitIfChanged(SignalId::ControllerTempC, static_cast<int32_t>(canGetBitsLE(d, 40, 8)) - 40);
        return true;
    case canid::BmsStatus:
        if (f.dlc < 8) return false;
        markSeen(Bms, f.timestampMs);
        emitIfChanged(SignalId::SocPercentX10, static_cast<int32_t>(canGetBitsLE(d, 0, 10)));
        emitIfChanged(SignalId::ChargingState, static_cast<int32_t>(canGetBitsLE(d, 10, 2)));
        emitIfChanged(SignalId::PackVoltageX10, static_cast<int32_t>(canGetBitsLE(d, 16, 16)));
        emitIfChanged(SignalId::PackCurrentAx10, canGetSignedLE(d, 32, 16));
        emitIfChanged(SignalId::PackTempC, static_cast<int32_t>(canGetBitsLE(d, 48, 8)) - 40);
        return true;
    case canid::BmsRange:
        if (f.dlc < 2) return false;
        emitIfChanged(SignalId::RangeKm, static_cast<int32_t>(canGetBitsLE(d, 0, 16)));
        return true;
    case canid::BodyLamps:
        if (f.dlc < 1) return false;
        markSeen(Body, f.timestampMs);
        emitIfChanged(SignalId::IndicatorLeft, static_cast<int32_t>(canGetBitsLE(d, 0, 1)));
        emitIfChanged(SignalId::IndicatorRight, static_cast<int32_t>(canGetBitsLE(d, 1, 1)));
        emitIfChanged(SignalId::HighBeam, static_cast<int32_t>(canGetBitsLE(d, 2, 1)));
        emitIfChanged(SignalId::LowBeam, static_cast<int32_t>(canGetBitsLE(d, 3, 1)));
        emitIfChanged(SignalId::Hazard, static_cast<int32_t>(canGetBitsLE(d, 4, 1)));
        return true;
    case canid::AbsStatus:
        if (f.dlc < 1) return false;
        markSeen(Abs, f.timestampMs);
        emitIfChanged(SignalId::AbsFault, static_cast<int32_t>(canGetBitsLE(d, 0, 1)));
        emitIfChanged(SignalId::AbsActive, static_cast<int32_t>(canGetBitsLE(d, 1, 1)));
        return true;
    case canid::Tpms:
        if (f.dlc < 4) return false;
        emitIfChanged(SignalId::TyreFrontPsiX10, static_cast<int32_t>(canGetBitsLE(d, 0, 16)));
        emitIfChanged(SignalId::TyreRearPsiX10, static_cast<int32_t>(canGetBitsLE(d, 16, 16)));
        return true;
    case canid::Odometer:
        if (f.dlc < 8) return false;
        emitIfChanged(SignalId::OdometerKmX10, static_cast<int32_t>(canGetBitsLE(d, 0, 32)));
        emitIfChanged(SignalId::TripAKmX10, static_cast<int32_t>(canGetBitsLE(d, 32, 32)));
        return true;
    case canid::Faults:
        if (f.dlc < 2) return false;
        emitIfChanged(SignalId::FaultCode, static_cast<int32_t>(canGetBitsLE(d, 0, 16)));
        return true;
    default:
        return false;
    }
}

void VehicleCanDecoder::checkTimeouts(uint32_t nowMs)
{
    for (uint8_t n = 0; n < NodeCount; ++n) {
        if (m_timedOut[n] || nowMs - m_lastSeen[n] < kTimeoutMs)
            continue;
        m_timedOut[n] = true;
        switch (static_cast<Node>(n)) {
        case Vcu:
            emitIfChanged(SignalId::ReadyToRide, 0);
            emitIfChanged(SignalId::FaultCode, timeoutFault(Vcu));
            break;
        case Motor:
            emitIfChanged(SignalId::MotorRpm, 0);
            emitIfChanged(SignalId::FaultCode, timeoutFault(Motor));
            break;
        case Bms:
            emitIfChanged(SignalId::FaultCode, timeoutFault(Bms));
            break;
        case Body:
            emitIfChanged(SignalId::IndicatorLeft, 0);
            emitIfChanged(SignalId::IndicatorRight, 0);
            break;
        case Abs:
            emitIfChanged(SignalId::AbsFault, 1);
            break;
        default:
            break;
        }
    }
}

} // namespace evb
