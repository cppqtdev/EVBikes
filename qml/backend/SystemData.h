#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <string>

struct SystemData : public Qul::Singleton<SystemData>
{
    enum AuthState { AuthIdle = 0, AuthScanning, AuthMatched, AuthDenied };
    enum SpeedoStyle { SpeedoClassic = 0, SpeedoHex };

    Qul::Property<int> hours;
    Qul::Property<int> minutes;
    Qul::Property<bool> clockValid;
    Qul::Property<bool> use24Hour;
    Qul::Property<bool> nightMode;
    Qul::Property<int> brightness;
    Qul::Property<bool> locked;
    Qul::Property<int> pinAttemptsLeft;
    Qul::Property<bool> demoMode;

    Qul::Property<int> authState;
    Qul::Property<int> profileIndex;
    Qul::Property<int> seatLevel;
    Qul::Property<bool> autoTurnOff;
    Qul::Property<int> speedoStyle;
    Qul::Property<bool> antiTheftArmed;
    Qul::Property<int> theftCaptures;

    // Rider names belong to whoever enrolled the profile. Empty until then, so
    // the screen shows a slot number rather than a person nobody registered.
    Qul::Property<std::string> profile0Name;
    Qul::Property<std::string> profile1Name;
    Qul::Property<std::string> profile2Name;

    SystemData();

    void tick();
    void poll();
    bool submitPin(int pin);
    void setBrightnessLevel(int level);
    void toggleClockFormat();
    void setClock(int unixSeconds, int utcOffsetMinutes);

    void selectProfile(int index);
    void startScan();
    void completeScan();
    void setSeatLevel(int level);
    void toggleSpeedoStyle();
    void clearTheftCaptures();
};
