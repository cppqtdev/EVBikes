#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>
#include <string>

struct PhoneData : public Qul::Singleton<PhoneData>
{
    enum CallStatus : uint8_t { Idle = 0, Ringing = 1, Active = 2 };

    Qul::Property<bool> connected;
    Qul::Property<uint8_t> batteryPercent;
    Qul::Property<uint8_t> signalBars;
    Qul::Property<bool> internet;

    Qul::Property<uint8_t> callStatus;
    Qul::Property<std::string> callerName;

    Qul::Property<bool> mediaPlaying;
    Qul::Property<uint8_t> volume;
    Qul::Property<uint16_t> trackPositionS;
    Qul::Property<uint16_t> trackDurationS;
    Qul::Property<std::string> trackTitle;
    Qul::Property<std::string> trackArtist;

    Qul::Property<uint16_t> notificationSeq;
    Qul::Property<std::string> notificationSender;
    Qul::Property<std::string> notificationText;

    void mediaPlayPause();
    void mediaNext();
    void mediaPrevious();
    void answerCall();
    void rejectCall();
};
