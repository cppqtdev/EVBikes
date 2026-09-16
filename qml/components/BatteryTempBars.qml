import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend

// Battery (left, fills from the left) and pack temperature (right, fills from the right).
Item {
    id: bars

    property int battery: VehicleData.batteryPercent
    property int temperature: VehicleData.packTempC
    property int tempPercent: Math.max(0, Math.min(100, (temperature - 10) * 100 / 60))

    width: Theme.screenWidth
    height: 40

    Icon {
        x: 378
        y: 8
        size: 26
        source: "qrc:/assets/icons/26/battery_bolt.png"
        color: bars.battery <= 15 ? Theme.red : "#77706E"
    }

    Text {
        x: 404
        y: 2
        text: bars.battery + "%"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
        font.italic: true
    }

    ColorizedImage {
        x: 398
        y: 20
        source: "qrc:/assets/cluster/bar_pointed_left.png"
        color: "#3E4345"
    }

    Item {
        x: 398
        y: 20
        width: 190 * bars.battery / 100
        height: 12
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.animSlow }
        }

        ColorizedImage {
            source: "qrc:/assets/cluster/bar_pointed_left.png"
            color: bars.battery <= 15 ? "#B01E2E" : "#A9492B"
        }

        Rectangle {
            x: 12
            width: Math.max(0, parent.width - 12)
            height: 12
            radius: 6
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#A9492B" }
                GradientStop { position: 0.45; color: "#B5583A" }
                GradientStop { position: 0.8; color: "#DFA48C" }
                GradientStop { position: 1.0; color: "#B9D2BF" }
            }
        }
    }

    Text {
        x: 870 - width
        y: 0
        text: bars.temperature + "°c"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.italic: true
    }

    ColorizedImage {
        x: 684
        y: 20
        source: "qrc:/assets/cluster/bar_pointed_right.png"
        color: "#3E4345"
    }

    Item {
        x: 684 + 194 - width
        y: 20
        width: 194 * bars.tempPercent / 100
        height: 12
        clip: true

        Behavior on width {
            NumberAnimation { duration: Theme.animSlow }
        }

        ColorizedImage {
            x: parent.width - 194
            source: "qrc:/assets/cluster/bar_pointed_right.png"
            color: "#9FD8C0"
        }

        ColorizedImage {
            x: parent.width - 194
            source: "qrc:/assets/cluster/ruler.png"
            color: "#FFFFFF"
            opacity: 0.35
        }

        Rectangle {
            x: parent.width - 194
            width: 194
            height: 12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#009FD8C0" }
                GradientStop { position: 0.55; color: "#009FD8C0" }
                GradientStop { position: 0.78; color: "#C0C49484" }
                GradientStop { position: 1.0; color: "#FFD9644A" }
            }
        }
    }

    Icon {
        x: 878
        y: 8
        size: 28
        source: "qrc:/assets/icons/28/thermo.png"
        color: bars.temperature >= 55 ? "#D9644A" : "#A7C9BA"
    }
}
