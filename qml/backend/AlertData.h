#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

struct AlertData : public Qul::Singleton<AlertData>
{
    enum Kind {
        NoAlert = 0,
        LowTyreFront,
        LowTyreRear,
        LowBattery,
        SideStandDown,
        AbsFault,
        MotorOverheat,
        BatteryOverheat,
        CommunicationLost,
        CrashDetected
    };
    enum Level { LevelNone = 0, LevelInfo, LevelWarning, LevelCritical };

    Qul::Property<int> kind;
    Qul::Property<int> level;
    Qul::Property<bool> popupVisible;

    // Crash: phase 0 = crash card, 1 = SOS countdown. Overheat: 0 = "Slow down", 1 = protocols.
    Qul::Property<int> phase;
    Qul::Property<int> sosSecondsLeft;
    Qul::Property<bool> sosSent;
    Qul::Property<int> protocolIndex;
    Qul::Property<int> activeProtocol;

    void acknowledge();
    void update(int newKind, int newLevel);
    void tickSecond();
    void cancelSos();
    void activateProtocol();

private:
    int m_acknowledgedKind = 0;
    int m_secondsInAlert = 0;
    bool m_sosCancelled = false;
};
