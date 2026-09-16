import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend

// Gear letters, map toggle, ride-mode chip, mute and settings in the bottom housing.
Item {
    id: dock

    property bool mapActive: false
    property bool menuActive: false
    property int gear: VehicleData.driveState

    // Which dock control the handlebar keys are on. -1 while the menu is open.
    property int focusIndex: -1
    readonly property bool mapFocus: focusIndex === Router.dockMap
    readonly property bool modeFocus: focusIndex === Router.dockMode
    readonly property bool alertFocus: focusIndex === Router.dockAlerts
    readonly property bool settingsFocus: focusIndex === Router.dockSettings

    width: Theme.screenWidth
    height: 60

    Text {
        x: 393
        y: 17
        text: "R"
        color: dock.gear === VehicleData.Reverse ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: dock.gear === VehicleData.Reverse ? 30 : 18
    }

    Text {
        x: 411
        y: 17
        text: "P"
        color: dock.gear === VehicleData.Park ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: dock.gear === VehicleData.Park ? 30 : 18
    }

    Text {
        x: 427
        y: dock.gear === VehicleData.Drive || dock.gear === VehicleData.Neutral ? 7 : 17
        text: dock.gear === VehicleData.Neutral ? "N" : "D"
        color: dock.gear === VehicleData.Drive || dock.gear === VehicleData.Neutral ? Theme.textPrimary : Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: dock.gear === VehicleData.Drive || dock.gear === VehicleData.Neutral ? 30 : 18
    }

    ColorizedImage {
        x: 483
        y: 3
        source: "qrc:/assets/cluster/tile_slant.png"
        color: dock.mapFocus ? Theme.surfaceSelected : Theme.surface
        visible: dock.mapActive || dock.mapFocus

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Icon {
        x: 512
        y: 12
        size: 36
        source: "qrc:/assets/icons/36/compass.png"
        color: dock.mapActive || dock.mapFocus ? Theme.textPrimary : "#C3C8CA"
    }

    ColorizedImage {
        x: 590
        y: 0
        source: "qrc:/assets/cluster/chip.png"
        color: dock.modeFocus ? Theme.surfaceSelected : "#4E4E4E"
        visible: Theme.alertMode || dock.modeFocus

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Rectangle {
        x: 590
        y: 0
        width: 96
        height: 1
        color: "#9AA0A3"
        visible: Theme.alertMode || dock.modeFocus
    }

    Text {
        x: 590
        y: 10
        width: 96
        horizontalAlignment: Text.AlignHCenter
        text: Theme.alertMode ? qsTr("ALERT")
                              : (VehicleData.rideMode === VehicleData.Sport ? qsTr("SPORTS")
                                                                            : (VehicleData.rideMode === VehicleData.Normal ? qsTr("NORMAL") : qsTr("ECO")))
        color: Theme.alertMode || Theme.sport ? Theme.textPrimary : Theme.teal
        font.family: Theme.fontFamily
        font.pixelSize: VehicleData.rideMode === VehicleData.Eco || Theme.alertMode ? 26 : 22
        font.bold: true
        font.italic: true
    }

    ColorizedImage {
        x: 705
        y: 3
        source: "qrc:/assets/cluster/tile_slant.png"
        color: Theme.surfaceSelected
        visible: dock.alertFocus
    }

    Icon {
        x: 740
        y: 13
        size: 24
        source: Router.alertsMuted ? "qrc:/assets/icons/24/mute.png" : "qrc:/assets/icons/24/bell.png"
        color: dock.alertFocus ? Theme.textPrimary : "#A7ADB0"
    }

    ColorizedImage {
        x: 770
        y: 4
        source: "qrc:/assets/cluster/band_right.png"
        color: "#020202"
        visible: dock.menuActive || dock.settingsFocus
    }

    ColorizedImage {
        x: 770
        y: 4
        source: "qrc:/assets/cluster/band_right_lip.png"
        color: "#3A3A3A"
        visible: dock.menuActive || dock.settingsFocus
    }

    Icon {
        x: 832
        y: 13
        size: 24
        source: "qrc:/assets/icons/24/settings.png"
        color: dock.menuActive || dock.settingsFocus ? Theme.textPrimary : "#A7ADB0"
    }
}
