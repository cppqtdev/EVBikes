#pragma once

#include <qul/property.h>
#include <qul/singleton.h>

#include <string>

struct NavigationData : public Qul::Singleton<NavigationData>
{
    enum Maneuver {
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
    Qul::Property<int> maneuver;
    Qul::Property<int> roundaboutExit;
    Qul::Property<int> distanceToManeuverM;
    Qul::Property<int> distanceRemainingM;
    Qul::Property<int> etaMinutes;
    Qul::Property<int> laneMask;
    Qul::Property<int> recommendedLaneMask;
    Qul::Property<std::string> roadName;

    void clear();
};
