#pragma once

#include <qul/property.h>
#include <qul/singleton.h>
#include <qul/timer.h>

#include <cstdint>

struct Simulator : public Qul::Singleton<Simulator>
{
    Qul::Property<bool> running;
    Qul::Property<uint8_t> scenario;
    Qul::Property<bool> parked;

    Simulator();

    void start();
    void stop();
    void step(uint32_t elapsedMs);
    void nextScenario();
    void togglePark();

private:
    void onRuntimeTick();

    Qul::Timer m_timer;
    uint32_t m_lastTickMs = 0;
    uint32_t m_pollElapsedMs = 0;
    uint32_t m_clockElapsedMs = 0;
    bool m_started = false;
};
