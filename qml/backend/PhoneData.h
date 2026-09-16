#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <string>

struct PhoneData : public Qul::Singleton<PhoneData>
{
    enum CallStatus { Idle = 0, Ringing = 1, Active = 2 };

    Qul::Property<bool> connected;
    Qul::Property<int> batteryPercent;
    Qul::Property<int> signalBars;
    Qul::Property<bool> internet;

    Qul::Property<int> callStatus;
    Qul::Property<std::string> callerName;

    Qul::Property<bool> mediaPlaying;
    Qul::Property<int> volume;
    Qul::Property<int> trackPositionS;
    Qul::Property<int> trackDurationS;
    Qul::Property<std::string> trackTitle;
    Qul::Property<std::string> trackArtist;

    Qul::Property<int> notificationSeq;
    Qul::Property<std::string> notificationSender;
    Qul::Property<std::string> notificationText;

    void mediaPlayPause();
    void mediaNext();
    void mediaPrevious();
    void answerCall();
    void rejectCall();
};
