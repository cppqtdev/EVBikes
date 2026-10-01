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

    // The mode word has to sit inside its 96 px chip. NORMAL at 22 measured 95
    // wide, edge to edge with no room either side; the reference's ECO is 51.
    readonly property int modeSize: Theme.alertMode ? 22
                                  : (VehicleData.rideMode === VehicleData.Eco ? 26
                                  : (VehicleData.rideMode === VehicleData.Sport ? 19 : 18))

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
        y: 13
        size: 36
        source: "qrc:/assets/icons/36/compass.png"
        color: dock.mapActive || dock.mapFocus ? Theme.textPrimary : "#C3C8CA"
    }

    // The design carries a soft halo behind the mode word - between the letters
    // the reference sits about twenty levels above its plate - and it lifts
    // further when the keys are on it.
    ColorizedImage {
        x: 638 - 70
        y: 24 - 32
        source: "qrc:/assets/images/glow_blob_140x64.png"
        color: Theme.accent
        opacity: dock.modeFocus ? 0.42 : 0.16

        Behavior on opacity {
            NumberAnimation { duration: Theme.animNormal }
        }
    }

    // The plate under the mode word is there in every state on the reference,
    // and it is dark: measured about 32 levels while riding and 30 under the
    // alert word, where this drew a 78 only when alerting or focused. There is
    // no bright line along its top either.
    ColorizedImage {
        x: 590
        y: 0
        source: "qrc:/assets/cluster/chip.png"
        color: dock.modeFocus ? Theme.surfaceSelected : "#222222"

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }

    Text {
        x: 590
        y: 6
        width: 96
        height: 40
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Theme.alertMode ? qsTr("ALERT")
                              : (VehicleData.rideMode === VehicleData.Sport ? qsTr("SPORTS")
                                                                            : (VehicleData.rideMode === VehicleData.Normal ? qsTr("NORMAL") : qsTr("ECO")))
        color: Theme.alertMode || Theme.sport ? Theme.textPrimary : Theme.teal
        font.family: Theme.fontFamily
        font.pixelSize: dock.modeSize
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
        y: 10
        source: "qrc:/assets/cluster/band_right.png"
        color: "#020202"
        visible: dock.menuActive || dock.settingsFocus
    }

    ColorizedImage {
        x: 770
        y: 10
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
