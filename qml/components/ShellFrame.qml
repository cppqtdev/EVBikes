import QtQuick
import QtQuickUltralite.Extras
import ClusterCore

// Cluster body: shell, housings and edge glow. All pre-rendered Alpha8 art.
Item {
    id: frame

    property int glowStyle: 1
    property color glowColor: Theme.glow
    property bool showChannel: true
    property color floorColor: Theme.red
    property real floorOpacity: 0.0
    property real centerLift: 0.06

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        source: "qrc:/assets/cluster/shell_backing.png"
        color: Theme.black
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/shell_fill.png"
        color: Theme.shell
        visible: frame.glowStyle === 0
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/shell_ride.png"
        color: Theme.shell
        visible: frame.glowStyle !== 0
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/shell_vignette.png"
        color: "#FFFFFF"
        opacity: frame.centerLift
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/floor_glow.png"
        color: frame.floorColor
        opacity: frame.floorOpacity
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animSlow }
        }
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/panel_haze.png"
        color: frame.glowColor
        opacity: 0.22
        visible: frame.showChannel
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/bar_channel.png"
        color: Theme.channel
        visible: frame.showChannel
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/shell_edge.png"
        color: "#6A7073"
        visible: frame.glowStyle === 0
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/housing_top.png"
        color: Theme.housing
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/housing_bottom.png"
        color: Theme.housingBottom
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/housing_light.png"
        color: "#FFFFFF"
        opacity: 0.35
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/glow_ride.png"
        color: frame.glowColor
        visible: frame.glowStyle === 1

        Behavior on color {
            ColorAnimation { duration: Theme.animSlow }
        }
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/bar_edge.png"
        color: frame.glowColor
        opacity: 0.45
        visible: frame.glowStyle === 1 && frame.showChannel
    }

    ColorizedImage {
        source: "qrc:/assets/cluster/glow_alert.png"
        color: frame.glowColor
        visible: frame.glowStyle === 2

        Behavior on color {
            ColorAnimation { duration: Theme.animSlow }
        }
    }
}
