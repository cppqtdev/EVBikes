#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

struct Simulator : public Qul::Singleton<Simulator>
{
    Qul::Property<bool> running;
    Qul::Property<int> scenario;
    Qul::Property<bool> parked;

    Simulator();

    void step(int elapsedMs);
    void nextScenario();
    void togglePark();
};
