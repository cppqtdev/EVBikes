#pragma once

#include <qul/signal.h>
#include <qul/singleton.h>

#include <cstdint>

struct ClusterInput : public Qul::Singleton<ClusterInput>
{
    enum Button : uint8_t { Up = 0, Down, Left, Right, Ok, Mode, Back };
    enum Action : uint8_t { Press = 0, LongPress };

    // QML signal slots use its canonical int type; the hardware API stays byte-sized.
    Qul::Signal<void(int button, int action)> buttonEvent;

    void inject(uint8_t button, uint8_t action);
};
