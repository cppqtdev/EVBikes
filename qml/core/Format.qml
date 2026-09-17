pragma Singleton
import QtQuick
import ClusterBackend

QtObject {
    function pad2(value) {
        return (value < 10 ? "0" : "") + value
    }

    function clockText(hours, minutes, use24) {
        if (use24)
            return pad2(hours) + ":" + pad2(minutes)
        var h = hours % 12
        if (h === 0)
            h = 12
        return h + ":" + pad2(minutes)
    }

    function amPm(hours, use24) {
        if (use24)
            return ""
        return hours < 12 ? "am" : "pm"
    }

    // Everything below the screen works in kilometres. The rider's choice of
    // units is applied here, where the number is drawn, so no reading is ever
    // stored or sent converted.
    readonly property real milesPerKm: 0.621371
    readonly property real feetPerMetre: 3.28084
    readonly property int feetPerMile: 5280

    function speedValue(kmh) {
        return SystemData.useMiles ? Math.round(kmh * milesPerKm) : kmh
    }

    function speedUnit() {
        return SystemData.useMiles ? qsTr("MPH") : qsTr("KPH")
    }

    function speedUnitWord() {
        return SystemData.useMiles ? qsTr("Mph") : qsTr("Kmph")
    }

    function distanceValueKm(km) {
        return SystemData.useMiles ? Math.round(km * milesPerKm) : km
    }

    function distanceUnitName() {
        return SystemData.useMiles ? qsTr("mi") : qsTr("km")
    }

    function tenthsKm(valueX10) {
        return tenths(SystemData.useMiles ? Math.round(valueX10 * milesPerKm) : valueX10)
    }

    function distanceValue(meters) {
        if (SystemData.useMiles) {
            var feet = meters * feetPerMetre
            if (feet >= feetPerMile * 10)
                return "" + Math.round(feet / feetPerMile)
            if (feet >= feetPerMile)
                return Math.floor(feet / feetPerMile) + "." + Math.floor((feet % feetPerMile) / (feetPerMile / 10))
            if (feet >= 500)
                return "" + Math.round(feet / 100) * 100
            return "" + Math.round(feet / 10) * 10
        }
        if (meters >= 10000)
            return "" + Math.round(meters / 1000)
        if (meters >= 1000)
            return Math.floor(meters / 1000) + "." + Math.floor((meters % 1000) / 100)
        if (meters >= 100)
            return "" + Math.round(meters / 50) * 50
        return "" + Math.round(meters / 10) * 10
    }

    function distanceUnit(meters) {
        if (SystemData.useMiles)
            return meters * feetPerMetre >= feetPerMile ? qsTr("mi") : qsTr("ft")
        return meters >= 1000 ? "km" : "m"
    }

    function tenths(valueX10) {
        return Math.floor(valueX10 / 10) + "." + Math.abs(valueX10 % 10)
    }

    function durationText(seconds) {
        return Math.floor(seconds / 60) + ":" + pad2(seconds % 60)
    }

    function etaText(minutes) {
        if (minutes < 60)
            return minutes + " min"
        return Math.floor(minutes / 60) + " h " + (minutes % 60) + " min"
    }

    function turnIcon(maneuver) {
        if (maneuver === NavigationData.Straight) return "qrc:/assets/turns/28/straight.png"
        if (maneuver === NavigationData.SlightLeft) return "qrc:/assets/turns/28/slight_left.png"
        if (maneuver === NavigationData.Left) return "qrc:/assets/turns/28/left.png"
        if (maneuver === NavigationData.SharpLeft) return "qrc:/assets/turns/28/sharp_left.png"
        if (maneuver === NavigationData.SlightRight) return "qrc:/assets/turns/28/slight_right.png"
        if (maneuver === NavigationData.Right) return "qrc:/assets/turns/28/right.png"
        if (maneuver === NavigationData.SharpRight) return "qrc:/assets/turns/28/sharp_right.png"
        if (maneuver === NavigationData.UTurnLeft) return "qrc:/assets/turns/28/uturn_left.png"
        if (maneuver === NavigationData.UTurnRight) return "qrc:/assets/turns/28/uturn_right.png"
        if (maneuver === NavigationData.RoundaboutEnter) return "qrc:/assets/turns/28/roundabout.png"
        if (maneuver === NavigationData.RoundaboutExit) return "qrc:/assets/turns/28/roundabout_exit.png"
        if (maneuver === NavigationData.ForkLeft) return "qrc:/assets/turns/28/fork_left.png"
        if (maneuver === NavigationData.ForkRight) return "qrc:/assets/turns/28/fork_right.png"
        if (maneuver === NavigationData.MergeLeft) return "qrc:/assets/turns/28/merge_left.png"
        if (maneuver === NavigationData.MergeRight) return "qrc:/assets/turns/28/merge_right.png"
        if (maneuver === NavigationData.Destination) return "qrc:/assets/turns/28/destination.png"
        return "qrc:/assets/icons/28/nav.png"
    }

    function turnText(maneuver, exitNumber) {
        if (maneuver === NavigationData.Straight) return qsTr("Continue straight")
        if (maneuver === NavigationData.SlightLeft) return qsTr("Keep slight left")
        if (maneuver === NavigationData.Left) return qsTr("Turn left")
        if (maneuver === NavigationData.SharpLeft) return qsTr("Sharp left")
        if (maneuver === NavigationData.SlightRight) return qsTr("Keep slight right")
        if (maneuver === NavigationData.Right) return qsTr("Turn right")
        if (maneuver === NavigationData.SharpRight) return qsTr("Sharp right")
        if (maneuver === NavigationData.UTurnLeft || maneuver === NavigationData.UTurnRight) return qsTr("Make a U-turn")
        if (maneuver === NavigationData.RoundaboutEnter) return qsTr("At roundabout take exit ") + exitNumber
        if (maneuver === NavigationData.RoundaboutExit) return qsTr("Exit the roundabout")
        if (maneuver === NavigationData.ForkLeft) return qsTr("Keep left at fork")
        if (maneuver === NavigationData.ForkRight) return qsTr("Keep right at fork")
        if (maneuver === NavigationData.MergeLeft || maneuver === NavigationData.MergeRight) return qsTr("Merge")
        if (maneuver === NavigationData.Destination) return qsTr("Arriving at destination")
        return ""
    }

    function digitAt(value, position) {
        var v = Math.floor(value)
        for (var i = 0; i < position; i++)
            v = Math.floor(v / 10)
        return "" + (v % 10)
    }

    // Contacts and reminders come off the phone link, three slots each. An
    // unpaired phone leaves them empty, which is the truth rather than a list
    // of people the firmware made up.
    function contactName(index) {
        if (index === 0) return PhoneListData.contact0Name
        if (index === 1) return PhoneListData.contact1Name
        return PhoneListData.contact2Name
    }

    function contactBody(index) {
        if (index === 0) return PhoneListData.contact0Text
        if (index === 1) return PhoneListData.contact1Text
        return PhoneListData.contact2Text
    }

    function contactInitial(index) {
        if (index === 0) return PhoneListData.contact0Initial
        if (index === 1) return PhoneListData.contact1Initial
        return PhoneListData.contact2Initial
    }

    function reminderName(index) {
        if (index === 0) return PhoneListData.reminder0Name
        if (index === 1) return PhoneListData.reminder1Name
        return PhoneListData.reminder2Name
    }

    function reminderBody(index) {
        if (index === 0) return PhoneListData.reminder0Text
        if (index === 1) return PhoneListData.reminder1Text
        return PhoneListData.reminder2Text
    }

    function reminderInitial(index) {
        if (index === 0) return PhoneListData.reminder0Initial
        if (index === 1) return PhoneListData.reminder1Initial
        return PhoneListData.reminder2Initial
    }

    function profileName(index) {
        if (index === 0) return SystemData.profile0Name !== "" ? SystemData.profile0Name : qsTr("RIDER 1")
        if (index === 1) return SystemData.profile1Name !== "" ? SystemData.profile1Name : qsTr("RIDER 2")
        return SystemData.profile2Name !== "" ? SystemData.profile2Name : qsTr("RIDER 3")
    }

    function alertTitle(kind) {
        if (kind === AlertData.LowTyreFront) return qsTr("TIRE PSI LOW")
        if (kind === AlertData.LowTyreRear) return qsTr("TIRE PSI LOW")
        if (kind === AlertData.LowBattery) return qsTr("BATTERY LOW")
        if (kind === AlertData.SideStandDown) return qsTr("SIDE STAND DOWN")
        if (kind === AlertData.AbsFault) return qsTr("ABS FAULT")
        if (kind === AlertData.MotorOverheat) return qsTr("MOTOR OVERHEATING")
        if (kind === AlertData.BatteryOverheat) return qsTr("BATTERY OVERHEATING")
        if (kind === AlertData.CommunicationLost) return qsTr("SYSTEM FAULT")
        if (kind === AlertData.CrashDetected) return qsTr("CRASH DETECTED")
        return ""
    }

    function alertAdvice(kind) {
        if (kind === AlertData.LowTyreFront || kind === AlertData.LowTyreRear) return qsTr("Tire Inflation Required")
        if (kind === AlertData.LowBattery) return qsTr("Find a charging station")
        if (kind === AlertData.SideStandDown) return qsTr("Lift the side stand")
        if (kind === AlertData.AbsFault) return qsTr("Ride carefully. Visit service centre")
        if (kind === AlertData.MotorOverheat || kind === AlertData.BatteryOverheat) return qsTr("Slow down!")
        if (kind === AlertData.CommunicationLost) return qsTr("Stop safely and restart the bike")
        if (kind === AlertData.CrashDetected) return qsTr("SOS sent to emergency contacts")
        return ""
    }

    function routeImage(maneuver) {
        if (maneuver === NavigationData.SlightLeft || maneuver === NavigationData.ForkLeft || maneuver === NavigationData.MergeLeft)
            return "qrc:/assets/cluster/route_slight_left.png"
        if (maneuver === NavigationData.SlightRight || maneuver === NavigationData.ForkRight || maneuver === NavigationData.MergeRight)
            return "qrc:/assets/cluster/route_slight_right.png"
        if (maneuver === NavigationData.Left) return "qrc:/assets/cluster/route_left.png"
        if (maneuver === NavigationData.Right) return "qrc:/assets/cluster/route_right.png"
        if (maneuver === NavigationData.SharpLeft) return "qrc:/assets/cluster/route_sharp_left.png"
        if (maneuver === NavigationData.SharpRight) return "qrc:/assets/cluster/route_sharp_right.png"
        if (maneuver === NavigationData.UTurnLeft) return "qrc:/assets/cluster/route_uturn_left.png"
        if (maneuver === NavigationData.UTurnRight) return "qrc:/assets/cluster/route_uturn_right.png"
        if (maneuver === NavigationData.RoundaboutEnter || maneuver === NavigationData.RoundaboutExit)
            return "qrc:/assets/cluster/route_roundabout.png"
        if (maneuver === NavigationData.Destination) return "qrc:/assets/cluster/route_destination.png"
        return "qrc:/assets/cluster/route_straight.png"
    }

    function hexRouteImage(maneuver) {
        if (maneuver === NavigationData.SlightLeft || maneuver === NavigationData.ForkLeft || maneuver === NavigationData.MergeLeft)
            return "qrc:/assets/cluster/hexroute_slight_left.png"
        if (maneuver === NavigationData.SlightRight || maneuver === NavigationData.ForkRight || maneuver === NavigationData.MergeRight)
            return "qrc:/assets/cluster/hexroute_slight_right.png"
        if (maneuver === NavigationData.Left) return "qrc:/assets/cluster/hexroute_left.png"
        if (maneuver === NavigationData.Right) return "qrc:/assets/cluster/hexroute_right.png"
        if (maneuver === NavigationData.SharpLeft) return "qrc:/assets/cluster/hexroute_sharp_left.png"
        if (maneuver === NavigationData.SharpRight) return "qrc:/assets/cluster/hexroute_sharp_right.png"
        if (maneuver === NavigationData.UTurnLeft) return "qrc:/assets/cluster/hexroute_uturn_left.png"
        if (maneuver === NavigationData.UTurnRight) return "qrc:/assets/cluster/hexroute_uturn_right.png"
        if (maneuver === NavigationData.RoundaboutEnter || maneuver === NavigationData.RoundaboutExit)
            return "qrc:/assets/cluster/hexroute_roundabout.png"
        if (maneuver === NavigationData.Destination) return "qrc:/assets/cluster/hexroute_destination.png"
        return "qrc:/assets/cluster/hexroute_straight.png"
    }

    function alertIcon(kind) {
        if (kind === AlertData.LowTyreFront || kind === AlertData.LowTyreRear) return "qrc:/assets/icons/72/tyre.png"
        if (kind === AlertData.LowBattery) return "qrc:/assets/icons/72/battery_fault.png"
        if (kind === AlertData.SideStandDown) return "qrc:/assets/icons/72/side_stand.png"
        if (kind === AlertData.AbsFault) return "qrc:/assets/icons/72/abs.png"
        if (kind === AlertData.MotorOverheat || kind === AlertData.BatteryOverheat) return "qrc:/assets/icons/72/temp.png"
        if (kind === AlertData.CrashDetected) return "qrc:/assets/icons/72/sos.png"
        return "qrc:/assets/icons/72/warning.png"
    }
}
