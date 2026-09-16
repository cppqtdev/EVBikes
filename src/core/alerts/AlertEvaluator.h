#pragma once

#include <cstdint>

namespace evb {

// Higher value wins when several alerts are active.
enum class AlertKind : uint8_t {
    None = 0,
    LowTyreFront,
    LowTyreRear,
    LowBattery,
    SideStandDown,
    AbsFault,
    MotorOverheat,
    BatteryOverheat,
    CommunicationLost,
    CrashDetected,
};

enum class AlertLevel : uint8_t { None = 0, Info, Warning, Critical };

struct AlertInputs
{
    int32_t speedKmhX10 = 0;
    int32_t socPercentX10 = 1000;
    int32_t packTempC = 25;
    int32_t motorTempC = 25;
    int32_t tyreFrontPsiX10 = 320;
    int32_t tyreRearPsiX10 = 320;
    bool sideStandDown = false;
    bool absFault = false;
    bool crashDetected = false;
    int32_t faultCode = 0;
};

struct AlertThresholds
{
    int32_t lowSocX10 = 150;
    int32_t criticalSocX10 = 50;
    int32_t packWarnC = 55;
    int32_t packCriticalC = 60;
    int32_t motorWarnC = 110;
    int32_t motorCriticalC = 130;
    int32_t tyreLowPsiX10 = 280;
    int32_t hysteresisX10 = 10;
};

struct AlertResult
{
    AlertKind kind = AlertKind::None;
    AlertLevel level = AlertLevel::None;
};

class AlertEvaluator
{
public:
    explicit AlertEvaluator(const AlertThresholds &t = AlertThresholds{}) : m_t(t) {}

    AlertResult evaluate(const AlertInputs &in);

private:
    AlertThresholds m_t;
    bool m_tyreFrontLow = false;
    bool m_tyreRearLow = false;
    bool m_socLow = false;
};

} // namespace evb
