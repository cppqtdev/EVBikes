#pragma once

#include <functional>
#include <utility>

// Desktop stand-in for Qt Quick Ultralite's Qul::Property.
// Adds a change hook so the Qt 6 bridge can emit NOTIFY signals.
namespace Qul {

template <typename T>
class Property
{
public:
    Property() = default;
    explicit Property(const T &v) : m_value(v) {}

    const T &value() const { return m_value; }

    void setValue(const T &v)
    {
        if (m_value == v)
            return;
        m_value = v;
        if (m_onChanged)
            m_onChanged();
    }

    void setOnChanged(std::function<void()> fn) { m_onChanged = std::move(fn); }

private:
    T m_value{};
    std::function<void()> m_onChanged;
};

} // namespace Qul
