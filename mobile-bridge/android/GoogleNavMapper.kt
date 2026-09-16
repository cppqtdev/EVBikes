package com.evbikes.bridge

import com.google.android.libraries.mapsplatform.turnbyturn.model.Maneuver
import com.google.android.libraries.mapsplatform.turnbyturn.model.NavInfo
import com.evbikes.bridge.PhoneLinkCodec.Maneuver as M

// Maps Google Navigation SDK turn-by-turn data to the cluster protocol.
object GoogleNavMapper {

    fun toNavUpdate(info: NavInfo): PhoneLinkCodec.NavUpdate? {
        val step = info.currentStep ?: return null
        val maneuver = mapManeuver(step.maneuver)
        var laneMask = 0
        var recommended = 0
        step.lanes?.take(4)?.forEachIndexed { i, lane ->
            laneMask = laneMask or (1 shl i)
            if (lane.laneDirections().any { it.isRecommended }) recommended = recommended or (1 shl i)
        }
        return PhoneLinkCodec.NavUpdate(
            maneuver = maneuver,
            roundaboutExit = step.roundaboutTurnNumber,
            distanceToManeuverM = info.distanceToCurrentStepMeters ?: 0,
            distanceRemainingM = info.distanceToFinalDestinationMeters ?: 0,
            etaMinutes = ((info.timeToFinalDestinationSeconds ?: 0) + 59) / 60,
            laneMask = laneMask,
            recommendedLaneMask = recommended,
            roadName = step.simpleRoadName ?: step.fullRoadName ?: "",
        )
    }

    fun mapManeuver(m: Int): M = when (m) {
        Maneuver.STRAIGHT, Maneuver.NAME_CHANGE, Maneuver.DEPART -> M.STRAIGHT
        Maneuver.TURN_SLIGHT_LEFT, Maneuver.TURN_KEEP_LEFT, Maneuver.ON_RAMP_SLIGHT_LEFT,
        Maneuver.OFF_RAMP_SLIGHT_LEFT, Maneuver.ON_RAMP_KEEP_LEFT, Maneuver.OFF_RAMP_KEEP_LEFT -> M.SLIGHT_LEFT
        Maneuver.TURN_LEFT, Maneuver.ON_RAMP_LEFT, Maneuver.OFF_RAMP_LEFT -> M.LEFT
        Maneuver.TURN_SHARP_LEFT, Maneuver.ON_RAMP_SHARP_LEFT, Maneuver.OFF_RAMP_SHARP_LEFT -> M.SHARP_LEFT
        Maneuver.TURN_SLIGHT_RIGHT, Maneuver.TURN_KEEP_RIGHT, Maneuver.ON_RAMP_SLIGHT_RIGHT,
        Maneuver.OFF_RAMP_SLIGHT_RIGHT, Maneuver.ON_RAMP_KEEP_RIGHT, Maneuver.OFF_RAMP_KEEP_RIGHT -> M.SLIGHT_RIGHT
        Maneuver.TURN_RIGHT, Maneuver.ON_RAMP_RIGHT, Maneuver.OFF_RAMP_RIGHT -> M.RIGHT
        Maneuver.TURN_SHARP_RIGHT, Maneuver.ON_RAMP_SHARP_RIGHT, Maneuver.OFF_RAMP_SHARP_RIGHT -> M.SHARP_RIGHT
        Maneuver.TURN_U_TURN_COUNTERCLOCKWISE, Maneuver.ON_RAMP_U_TURN_COUNTERCLOCKWISE,
        Maneuver.OFF_RAMP_U_TURN_COUNTERCLOCKWISE -> M.UTURN_LEFT
        Maneuver.TURN_U_TURN_CLOCKWISE, Maneuver.ON_RAMP_U_TURN_CLOCKWISE,
        Maneuver.OFF_RAMP_U_TURN_CLOCKWISE -> M.UTURN_RIGHT
        Maneuver.ROUNDABOUT_EXIT_CLOCKWISE, Maneuver.ROUNDABOUT_EXIT_COUNTERCLOCKWISE -> M.ROUNDABOUT_EXIT
        Maneuver.FORK_LEFT -> M.FORK_LEFT
        Maneuver.FORK_RIGHT -> M.FORK_RIGHT
        Maneuver.MERGE_LEFT -> M.MERGE_LEFT
        Maneuver.MERGE_RIGHT, Maneuver.MERGE_UNSPECIFIED -> M.MERGE_RIGHT
        Maneuver.DESTINATION, Maneuver.DESTINATION_LEFT, Maneuver.DESTINATION_RIGHT -> M.DESTINATION
        else -> if (isRoundabout(m)) M.ROUNDABOUT_ENTER else M.STRAIGHT
    }

    private fun isRoundabout(m: Int): Boolean = m in setOf(
        Maneuver.ROUNDABOUT_CLOCKWISE, Maneuver.ROUNDABOUT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_LEFT_CLOCKWISE, Maneuver.ROUNDABOUT_LEFT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_RIGHT_CLOCKWISE, Maneuver.ROUNDABOUT_RIGHT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_SHARP_LEFT_CLOCKWISE, Maneuver.ROUNDABOUT_SHARP_LEFT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_SHARP_RIGHT_CLOCKWISE, Maneuver.ROUNDABOUT_SHARP_RIGHT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_SLIGHT_LEFT_CLOCKWISE, Maneuver.ROUNDABOUT_SLIGHT_LEFT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_SLIGHT_RIGHT_CLOCKWISE, Maneuver.ROUNDABOUT_SLIGHT_RIGHT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_STRAIGHT_CLOCKWISE, Maneuver.ROUNDABOUT_STRAIGHT_COUNTERCLOCKWISE,
        Maneuver.ROUNDABOUT_U_TURN_CLOCKWISE, Maneuver.ROUNDABOUT_U_TURN_COUNTERCLOCKWISE,
    )
}
