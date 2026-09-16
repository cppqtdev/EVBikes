import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Low tyre pressure card over the dimmed riding screen.
Item {
    id: tyre

    property bool front: AlertData.kind === AlertData.LowTyreFront
    property int psiX10: front ? VehicleData.tyreFrontPsiX10 : VehicleData.tyreRearPsiX10
    property int recommendedX10: 320
    property int scaleMinX10: 200
    property int scaleMaxX10: 360

    width: Theme.screenWidth
    height: Theme.screenHeight

    ColorizedImage {
        x: 202
        y: 69
        source: "qrc:/assets/cluster/card_tyre.png"
        color: "#202020"
        opacity: 0.94
    }

    Image {
        x: 585
        y: 86
        source: "qrc:/assets/cluster/bike_110.png"
    }

    ColorizedImage {
        x: 585
        y: 86
        source: "qrc:/assets/cluster/bike_110_wheel.png"
        color: Theme.red
        opacity: 0.85
    }

    Text {
        x: 0
        y: 172
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: Format.alertTitle(AlertData.kind)
        color: "#D4203A"
        font.family: Theme.fontFamily
        font.pixelSize: 28
        font.bold: true
    }

    Text {
        x: 0
        y: 234
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: Format.alertAdvice(AlertData.kind) + (tyre.front ? qsTr(" (front)") : qsTr(" (rear)"))
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    Text {
        x: 580 + 128 * (tyre.recommendedX10 - tyre.scaleMinX10) / (tyre.scaleMaxX10 - tyre.scaleMinX10) - 30
        y: 267
        width: 60
        horizontalAlignment: Text.AlignHCenter
        text: Math.round(tyre.recommendedX10 / 10) + " psi"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }

    Rectangle {
        x: 580
        y: 295
        width: 128
        height: 12
        radius: 3
        color: "#555A5D"
    }

    Rectangle {
        x: 580
        y: 295
        width: Math.max(4, 128 * (tyre.psiX10 - tyre.scaleMinX10) / (tyre.scaleMaxX10 - tyre.scaleMinX10))
        height: 12
        radius: 3
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "#7A1622" }
            GradientStop { position: 1.0; color: "#E3263A" }
        }
    }

    Rectangle {
        x: 580 + 128 * (tyre.psiX10 - tyre.scaleMinX10) / (tyre.scaleMaxX10 - tyre.scaleMinX10) - 1
        y: 291
        width: 2
        height: 20
        color: Theme.textPrimary
    }

    Rectangle {
        x: 580 + 128 * (tyre.recommendedX10 - tyre.scaleMinX10) / (tyre.scaleMaxX10 - tyre.scaleMinX10) - 1
        y: 285
        width: 3
        height: 22
        color: "#7CFF7A"
    }

    Text {
        x: 580 + 128 * (tyre.psiX10 - tyre.scaleMinX10) / (tyre.scaleMaxX10 - tyre.scaleMinX10) - 30
        y: 311
        width: 60
        horizontalAlignment: Text.AlignHCenter
        text: Format.tenths(tyre.psiX10) + " psi"
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }

    Text {
        x: 0
        y: 336
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("OK to dismiss")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 12
    }
}
