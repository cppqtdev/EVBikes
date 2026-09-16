#pragma once

#include <qul/signal.h>
#include <qul/singleton.h>

struct ClusterInput : public Qul::Singleton<ClusterInput>
{
    enum Button { Up = 0, Down, Left, Right, Ok, Mode, Back };
    enum Action { Press = 0, LongPress };

    Qul::Signal<void(int button, int action)> buttonEvent;

    void inject(int button, int action);
};
