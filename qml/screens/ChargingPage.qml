import QtQuick
import QtQuick.Shapes
import ClusterCore
import ClusterBackend
import ClusterComponents

PageBase {
    id: page

    pageId: Router.menuCharging

    property int soc: VehicleData.batteryPercent
    property real target: Math.max(0.01, Math.min(0.999, soc / 100))
    property real fraction: target
    // Two half-sweeps, so neither arc ever exceeds 180 degrees and the ring
    // never needs useLargeArc, which is where the old one rendered ragged.
    property real midAngle: (-90 + 180 * fraction) * Math.PI / 180
    property real endAngle: (-90 + 360 * fraction) * Math.PI / 180
    property int minutesLeft: Math.round((100 - soc) * 0.75)
    property bool plugged: VehicleData.chargeState === VehicleData.Charging

    readonly property int ringX: 570
    readonly property int ringY: 117
    readonly property int ringR: 66
    readonly property int ringSize: 150

    Behavior on fraction {
        NumberAnimation { duration: Theme.animSlow }
    }

    Text {
        x: 0
        y: 74
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: page.plugged ? qsTr("CHARGING GUN INSERTED") : qsTr("CHARGER NOT CONNECTED")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 300
        y: 150
        width: 200
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("AUTO TURNOFF")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
        font.bold: true
    }

    ToggleSwitch {
        x: 355
        y: 187
        checked: SystemData.autoTurnOff
    }

    Shape {
        x: page.ringX
        y: page.ringY
        width: page.ringSize
        height: page.ringSize

        ShapePath {
            strokeColor: "#1F1F1F"
            strokeWidth: 12
            fillColor: "transparent"
            startX: page.ringSize / 2
            startY: page.ringSize / 2 - page.ringR
            PathArc { x: page.ringSize / 2; y: page.ringSize / 2 + page.ringR; radiusX: page.ringR; radiusY: page.ringR }
            PathArc { x: page.ringSize / 2; y: page.ringSize / 2 - page.ringR; radiusX: page.ringR; radiusY: page.ringR }
        }

        ShapePath {
            strokeColor: "#B85A3C"
            strokeWidth: 11
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: page.ringSize / 2
            startY: page.ringSize / 2 - page.ringR

            PathArc {
                x: page.ringSize / 2 + page.ringR * Math.cos(page.midAngle)
                y: page.ringSize / 2 + page.ringR * Math.sin(page.midAngle)
                radiusX: page.ringR
                radiusY: page.ringR
            }

            PathArc {
                x: page.ringSize / 2 + page.ringR * Math.cos(page.endAngle)
                y: page.ringSize / 2 + page.ringR * Math.sin(page.endAngle)
                radiusX: page.ringR
                radiusY: page.ringR
            }
        }
    }

    Icon {
        x: 633
        y: 150
        size: 24
        source: "qrc:/assets/icons/28/plug.png"
        color: "#DADDDE"
        transform: Rotation {
            origin.x: 12
            origin.y: 12
            angle: 35
        }
    }

    Rectangle {
        x: 631
        y: 148
        width: 9
        height: 3
        radius: 1.5
        color: Theme.green
        visible: page.plugged
    }

    NumberReadout {
        id: socReadout
        x: 645 - (width + percentSign.width) / 2
        y: 186
        value: page.soc
        fit: true
        pixelSize: 30
        widthFactor: 0.6
        color: "#C0603F"
        bold: true
        duration: Theme.animSlow
    }

    Text {
        id: percentSign
        x: socReadout.x + socReadout.width
        y: 192
        text: "%"
        color: "#C0603F"
        font.family: Theme.fontFamily
        font.pixelSize: 24
        font.bold: true
    }

    Text {
        x: 812
        y: 150
        width: 200
        horizontalAlignment: Text.AlignHCenter
        text: page.minutesLeft + qsTr(" MINS")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 20
        font.bold: true
    }

    Text {
        x: 812
        y: 186
        width: 200
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("left to full charge")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 19
    }
}
