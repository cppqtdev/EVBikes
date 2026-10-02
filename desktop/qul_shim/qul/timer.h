#pragma once

#include <cstdint>
#include <functional>
#include <utility>

#ifdef EVB_QT_DESKTOP
#include <QTimer>

namespace Qul {

class Timer
{
public:
    Timer()
    {
        QObject::connect(&m_timer, &QTimer::timeout, [this]() {
            if (m_callback)
                m_callback();
        });
    }

    void setSingleShot(bool singleShot) { m_timer.setSingleShot(singleShot); }
    void onTimeout(std::function<void()> callback) { m_callback = std::move(callback); }
    void start(uint32_t intervalMs) { m_timer.start(static_cast<int>(intervalMs)); }
    void stop() { m_timer.stop(); }

private:
    QTimer m_timer;
    std::function<void()> m_callback;
};

} // namespace Qul

#else

// Host-only backend unit builds do not run the application event loop.
namespace Qul {

class Timer
{
public:
    void setSingleShot(bool) {}
    void onTimeout(std::function<void()> callback) { m_callback = std::move(callback); }
    void start(uint32_t) {}
    void stop() {}

private:
    std::function<void()> m_callback;
};

} // namespace Qul
#endif
