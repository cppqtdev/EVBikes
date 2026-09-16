#pragma once

namespace Qul {

template <typename T>
struct Singleton
{
    static T &instance()
    {
        static T inst;
        return inst;
    }
};

} // namespace Qul
