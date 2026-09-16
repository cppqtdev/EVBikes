#include "NavigationData.h"

void NavigationData::clear()
{
    active.setValue(false);
    maneuver.setValue(None);
    roundaboutExit.setValue(0);
    distanceToManeuverM.setValue(0);
    distanceRemainingM.setValue(0);
    etaMinutes.setValue(0);
    laneMask.setValue(0);
    recommendedLaneMask.setValue(0);
    roadName.setValue(std::string());
}
