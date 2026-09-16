#include "AlertData.h"

namespace {
constexpr int kCardSeconds = 3;
constexpr int kSosCountdownSeconds = 60;
}

void AlertData::update(int newKind, int newLevel)
{
    if (newKind != kind.value()) {
        m_secondsInAlert = 0;
        phase.setValue(0);
        protocolIndex.setValue(0);
        activeProtocol.setValue(-1);
        if (newKind != CrashDetected) {
            m_sosCancelled = false;
            sosSent.setValue(false);
        }
        if (newKind == CrashDetected)
            sosSecondsLeft.setValue(kSosCountdownSeconds);
    }
    if (newKind == NoAlert)
        m_acknowledgedKind = NoAlert;

    kind.setValue(newKind);
    level.setValue(newLevel);

    const bool crashHandled = newKind == CrashDetected && m_sosCancelled;
    const bool mustShow = newLevel == LevelCritical && !crashHandled;
    const bool canShow = newLevel >= LevelWarning && newKind != m_acknowledgedKind && !crashHandled;
    popupVisible.setValue(mustShow || canShow);
}

void AlertData::tickSecond()
{
    if (!popupVisible.value())
        return;
    ++m_secondsInAlert;

    const int k = kind.value();
    const bool phased = k == CrashDetected || k == MotorOverheat || k == BatteryOverheat;
    if (phased && phase.value() == 0 && m_secondsInAlert >= kCardSeconds)
        phase.setValue(1);

    if (k == CrashDetected && phase.value() == 1 && !sosSent.value()) {
        const int left = sosSecondsLeft.value() - 1;
        sosSecondsLeft.setValue(left > 0 ? left : 0);
        if (left <= 0)
            sosSent.setValue(true);
    }
}

void AlertData::cancelSos()
{
    if (kind.value() != CrashDetected || sosSent.value())
        return;
    m_sosCancelled = true;
    popupVisible.setValue(false);
}

void AlertData::activateProtocol()
{
    activeProtocol.setValue(protocolIndex.value());
}

void AlertData::acknowledge()
{
    if (level.value() == LevelCritical)
        return;
    m_acknowledgedKind = kind.value();
    popupVisible.setValue(false);
}
