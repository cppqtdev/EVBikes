#include "AlertEvaluator.h"

namespace evb {

namespace {

bool withHysteresis(bool active, int32_t value, int32_t limit, int32_t hyst)
{
    return active ? value < limit + hyst : value < limit;
}

} // namespace

AlertResult AlertEvaluator::evaluate(const AlertInputs &in)
{
    m_tyreFrontLow = withHysteresis(m_tyreFrontLow, in.tyreFrontPsiX10, m_t.tyreLowPsiX10, m_t.hysteresisX10);
    m_tyreRearLow = withHysteresis(m_tyreRearLow, in.tyreRearPsiX10, m_t.tyreLowPsiX10, m_t.hysteresisX10);
    m_socLow = withHysteresis(m_socLow, in.socPercentX10, m_t.lowSocX10, m_t.hysteresisX10);

    if (in.crashDetected)
        return {AlertKind::CrashDetected, AlertLevel::Critical};
    if (in.faultCode >= 0x0100 && in.faultCode < 0x0300)
        return {AlertKind::CommunicationLost, AlertLevel::Critical};
    if (in.packTempC >= m_t.packCriticalC)
        return {AlertKind::BatteryOverheat, AlertLevel::Critical};
    if (in.motorTempC >= m_t.motorCriticalC)
        return {AlertKind::MotorOverheat, AlertLevel::Critical};
    if (in.sideStandDown && in.speedKmhX10 > 0)
        return {AlertKind::SideStandDown, AlertLevel::Critical};
    if (in.packTempC >= m_t.packWarnC)
        return {AlertKind::BatteryOverheat, AlertLevel::Warning};
    if (in.motorTempC >= m_t.motorWarnC)
        return {AlertKind::MotorOverheat, AlertLevel::Warning};
    if (in.absFault)
        return {AlertKind::AbsFault, AlertLevel::Warning};
    if (in.socPercentX10 <= m_t.criticalSocX10)
        return {AlertKind::LowBattery, AlertLevel::Critical};
    if (m_tyreFrontLow)
        return {AlertKind::LowTyreFront, AlertLevel::Warning};
    if (m_tyreRearLow)
        return {AlertKind::LowTyreRear, AlertLevel::Warning};
    if (m_socLow)
        return {AlertKind::LowBattery, AlertLevel::Warning};
    if (in.sideStandDown)
        return {AlertKind::SideStandDown, AlertLevel::Info};
    return {};
}

} // namespace evb
