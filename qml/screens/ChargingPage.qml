import QtQuick
import QtQuick.Shapes
import ClusterCore
import ClusterBackend
import ClusterComponents

PageBase {
    id: page

    pageId: Router.menuCharging

    property int soc: VehicleData.batteryPercent
    property real fraction: Math.max(0.01, Math.min(0.999, soc / 100))
    property real endAngle: (-90 + 360 * fraction) * Math.PI / 180
    property int minutesLeft: Math.round((100 - soc) * 0.75)
    property bool plugged: VehicleData.chargeState === VehicleData.Charging

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
        x: 545
        y: 92
        width: 200
        height: 200

        ShapePath {
            strokeColor: "#1F1F1F"
            strokeWidth: 16
            fillColor: "transparent"
            startX: 100
            startY: 8
            PathArc { x: 100; y: 192; radiusX: 92; radiusY: 92 }
            PathArc { x: 100; y: 8; radiusX: 92; radiusY: 92 }
        }

        ShapePath {
            strokeColor: "#B85A3C"
            strokeWidth: 14
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: 100
            startY: 8
            PathArc {
                x: 100 + 92 * Math.cos(page.endAngle)
                y: 100 + 92 * Math.sin(page.endAngle)
                radiusX: 92
                radiusY: 92
                useLargeArc: page.fraction > 0.5
            }
        }
    }

    Icon {
        x: 628
        y: 142
        size: 28
        source: "qrc:/assets/icons/28/plug.png"
        color: "#DADDDE"
        transform: Rotation {
            origin.x: 14
            origin.y: 14
            angle: 35
        }
    }

    Rectangle {
        x: 626
        y: 140
        width: 10
        height: 3
        radius: 1.5
        color: Theme.green
        visible: page.plugged
    }

    Text {
        x: 545
        y: 188
        width: 200
        horizontalAlignment: Text.AlignHCenter
        text: page.soc + "%"
        color: "#C0603F"
        font.family: Theme.fontFamily
        font.pixelSize: 34
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
