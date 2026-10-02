#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <cstdint>
#include <string>

struct NavigationData : public Qul::Singleton<NavigationData>
{
    enum Maneuver : uint8_t {
        None = 0,
        Straight,
        SlightLeft,
        Left,
        SharpLeft,
        SlightRight,
        Right,
        SharpRight,
        UTurnLeft,
        UTurnRight,
        RoundaboutEnter,
        RoundaboutExit,
        ForkLeft,
        ForkRight,
        MergeLeft,
        MergeRight,
        Destination
    };

    Qul::Property<bool> active;
    Qul::Property<uint8_t> maneuver;
    Qul::Property<uint8_t> roundaboutExit;
    Qul::Property<uint32_t> distanceToManeuverM;
    Qul::Property<uint32_t> distanceRemainingM;
    Qul::Property<uint16_t> etaMinutes;
    Qul::Property<uint8_t> laneMask;
    Qul::Property<uint8_t> recommendedLaneMask;
    Qul::Property<std::string> roadName;

    void clear();
};
