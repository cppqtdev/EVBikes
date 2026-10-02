#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>
#include <string>

struct SystemData : public Qul::Singleton<SystemData>
{
    enum AuthState : uint8_t { AuthIdle = 0, AuthScanning, AuthMatched, AuthDenied };
    enum SpeedoStyle : uint8_t { SpeedoClassic = 0, SpeedoHex };

    Qul::Property<uint8_t> hours;
    Qul::Property<uint8_t> minutes;
    Qul::Property<uint32_t> uptimeMs;
    Qul::Property<uint8_t> splashStep;
    Qul::Property<uint16_t> authElapsedMs;
    Qul::Property<uint16_t> preRideElapsedMs;
    Qul::Property<bool> menuHintVisible;
    Qul::Property<bool> notificationToastVisible;
    Qul::Property<bool> clockValid;
    Qul::Property<bool> use24Hour;
    // Distance and speed are held in kilometres throughout the backend. This
    // only changes what the screens draw, never what is stored or sent.
    Qul::Property<bool> useMiles;
    Qul::Property<bool> nightMode;
    Qul::Property<uint8_t> brightness;
    // True when brightness has to be applied by dimming the picture, because
    // this target's panel has no backlight the cluster can turn down.
    Qul::Property<bool> softwareDimming;
    Qul::Property<bool> locked;
    Qul::Property<uint8_t> pinAttemptsLeft;
    Qul::Property<bool> demoMode;

    Qul::Property<uint8_t> authState;
    Qul::Property<uint8_t> profileIndex;
    Qul::Property<uint8_t> seatLevel;
    Qul::Property<bool> autoTurnOff;
    Qul::Property<uint8_t> speedoStyle;
    Qul::Property<bool> antiTheftArmed;
    Qul::Property<uint8_t> theftCaptures;

    // Rider names belong to whoever enrolled the profile. Empty until then, so
    // the screen shows a slot number rather than a person nobody registered.
    Qul::Property<std::string> profile0Name;
    Qul::Property<std::string> profile1Name;
    Qul::Property<std::string> profile2Name;

    SystemData();

    void tick();
    void poll();
    void advanceRuntime(uint32_t elapsedMs);
    void setPreRideReady(bool ready);
    void showMenuHint();
    void showNotificationToast();
    bool submitPin(uint16_t pin);
    void setBrightnessLevel(uint8_t level);
    void toggleClockFormat();
    void toggleUnits();
    void setClock(uint32_t unixSeconds, int16_t utcOffsetMinutes);

    void selectProfile(int16_t index);
    void startScan();
    void completeScan();
    void setSeatLevel(int8_t level);
    void toggleSpeedoStyle();
    void clearTheftCaptures();

private:
    uint32_t m_splashElapsedMs = 0;
    uint16_t m_authElapsedMs = 0;
    uint16_t m_preRideElapsedMs = 0;
    uint16_t m_menuHintRemainingMs = 0;
    uint16_t m_toastRemainingMs = 0;
    bool m_preRideReady = false;
};
