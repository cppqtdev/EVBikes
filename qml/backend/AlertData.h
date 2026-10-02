#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>

struct AlertData : public Qul::Singleton<AlertData>
{
    enum Kind : uint8_t {
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
    enum Level : uint8_t { LevelNone = 0, LevelInfo, LevelWarning, LevelCritical };

    Qul::Property<uint8_t> kind;
    Qul::Property<uint8_t> level;
    Qul::Property<bool> popupVisible;

    // Crash: phase 0 = crash card, 1 = SOS countdown. Overheat: 0 = "Slow down", 1 = protocols.
    Qul::Property<uint8_t> phase;
    Qul::Property<uint8_t> sosSecondsLeft;
    Qul::Property<bool> sosSent;
    Qul::Property<uint8_t> protocolIndex;
    Qul::Property<int8_t> activeProtocol;

    void acknowledge();
    void update(uint8_t newKind, uint8_t newLevel);
    void tickSecond();
    void cancelSos();
    void activateProtocol();

private:
    uint8_t m_acknowledgedKind = 0;
    uint8_t m_secondsInAlert = 0;
    bool m_sosCancelled = false;
};
