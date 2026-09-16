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
        x: 380
        y: 5
        size: 22
        source: "qrc:/assets/icons/22/charging.png"
        color: bars.battery <= 15 ? Theme.red : "#C4613F"
    }

    Text {
        x: 404
        y: 0
        text: bars.battery + "%"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 15
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
            anchors.right: parent.right
            width: Math.min(40, parent.width)
            height: 12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00E08A68" }
                GradientStop { position: 1.0; color: "#C8E8A080" }
            }
        }
    }

    Text {
        x: 870 - width
        y: 0
        text: bars.temperature + "°c"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 15
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
            color: bars.temperature >= 55 ? "#E08A7A" : "#A9E4D0"
        }

        ColorizedImage {
            x: parent.width - 194
            source: "qrc:/assets/cluster/ruler.png"
            color: "#FFFFFF"
            opacity: 0.35
        }

        Rectangle {
            anchors.right: parent.right
            width: Math.min(22, parent.width)
            height: 12
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#00D9644A" }
                GradientStop { position: 1.0; color: "#FFD9644A" }
            }
        }
    }

    Icon {
        x: 878
        y: 6
        size: 28
        source: "qrc:/assets/icons/28/temp.png"
        color: "#D9DDDE"
    }

    Rectangle {
        x: 884
        y: 25
        width: 9
        height: 9
        radius: 4.5
        color: Theme.red
    }
}
