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
    // Outer border. The reference has nothing outside the contour, so this is
    // an addition by choice; edgeOpacity 0 returns to the measured design.
    property color edgeColor: "#5C5C5C"
    property real edgeOpacity: 0.85
    // The light along the housings is not one colour in every state. Measured
    // on the reference over the header: cool grey while riding, near white and
    // about twice as strong in sport, amber on a full-screen alert.
    property color housingLight: "#DEE8FF"
    property real housingLightOpacity: 0.62

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 63; y: 0
        source: "qrc:/assets/cluster/trimmed/shell_backing.png"
        color: Theme.black
    }

    ColorizedImage {
        x: 80; y: 4
        source: "qrc:/assets/cluster/trimmed/shell_fill.png"
        color: Theme.shell
        visible: frame.glowStyle === 0
    }

    ColorizedImage {
        x: 90; y: 3
        source: "qrc:/assets/cluster/trimmed/shell_ride.png"
        color: Theme.shell
        visible: frame.glowStyle !== 0
    }

    ColorizedImage {
        x: 84; y: 45
        source: "qrc:/assets/cluster/trimmed/ride_outline.png"
        color: frame.edgeColor
        opacity: frame.edgeOpacity
        visible: frame.glowStyle !== 0 && frame.edgeOpacity > 0
    }

    ColorizedImage {
        x: 128; y: 5
        source: "qrc:/assets/cluster/trimmed/shell_vignette.png"
        color: "#FFFFFF"
        opacity: frame.centerLift
    }

    ColorizedImage {
        x: 140; y: 311
        source: "qrc:/assets/cluster/trimmed/floor_glow.png"
        color: frame.floorColor
        opacity: frame.floorOpacity
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation { duration: Theme.animSlow }
        }
    }

    ColorizedImage {
        x: 112; y: 8
        source: "qrc:/assets/cluster/trimmed/panel_haze.png"
        color: frame.glowColor
        opacity: 0.22
        visible: frame.showChannel
    }

    ColorizedImage {
        x: 105; y: 94
        source: "qrc:/assets/cluster/trimmed/bar_channel.png"
        color: Theme.channel
        visible: frame.showChannel
    }

    ColorizedImage {
        x: 80; y: 4
        source: "qrc:/assets/cluster/trimmed/shell_edge.png"
        color: "#6A7073"
        visible: frame.glowStyle === 0
    }

    ColorizedImage {
        x: 358; y: 0
        source: "qrc:/assets/cluster/trimmed/housing_top.png"
        color: Theme.housing
    }

    ColorizedImage {
        x: 351; y: 409
        source: "qrc:/assets/cluster/trimmed/housing_bottom.png"
        color: Theme.housingBottom
    }

    ColorizedImage {
        x: 348; y: 0
        source: "qrc:/assets/cluster/trimmed/housing_light.png"
        color: frame.housingLight
        opacity: frame.housingLightOpacity

        Behavior on color {
            ColorAnimation { duration: Theme.animSlow }
        }

        Behavior on opacity {
            NumberAnimation { duration: Theme.animSlow }
        }
    }

    ColorizedImage {
        x: 84; y: 45
        source: "qrc:/assets/cluster/trimmed/glow_ride.png"
        color: frame.glowColor
        visible: frame.glowStyle === 1

        Behavior on color {
            ColorAnimation { duration: Theme.animSlow }
        }
    }

    ColorizedImage {
        x: 78; y: 45
        source: "qrc:/assets/cluster/trimmed/glow_alert.png"
        color: frame.glowColor
        visible: frame.glowStyle === 2

        Behavior on color {
            ColorAnimation { duration: Theme.animSlow }
        }
    }
}
