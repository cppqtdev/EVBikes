import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Overheating: "Slow Down!" first, then the protocol choices.
//
// Measured against frame_0770. The art on this screen is laid out about a
// centre line at 655, not the middle of the display, and the centred text was
// still at 640, so nothing lined up with anything.
Item {
    id: heat

    readonly property int axis: 655

    width: Theme.screenWidth
    height: Theme.screenHeight

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: AlertData.phase === 0

        GlowBand {
            x: heat.axis - width / 2
            y: 72
            width: 256
            height: 24
            bandColor: "#9A1426"
        }

        Text {
            x: heat.axis - Theme.screenWidth / 2
            y: 72
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: AlertData.kind === AlertData.BatteryOverheat ? qsTr("Battery Over Heating!") : qsTr("Over Heating!")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 22
        }

        // The side view, at the box the reference draws it in.
        Image {
            x: 568
            y: 131
            source: "qrc:/assets/cluster/bikeside_heat.png"
        }

        // 94 px across on the reference, which is a 108 icon once the outline's
        // own inset is taken off, and it sits at about half opacity over the bike.
        Icon {
            x: 599
            y: 111
            size: 108
            source: "qrc:/assets/icons/108/triangle.png"
            color: "#D60006"
            opacity: 0.5
        }

        Ribbon {
            x: heat.axis - width / 2
            y: 242
            fontSize: 22
            text: qsTr("PROTOCOLS")
        }

        Text {
            x: heat.axis - 4 - Theme.screenWidth / 2
            y: 298
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Slow Down!")
            color: "#D60006"
            font.family: Theme.fontFamily
            font.pixelSize: 52
            font.bold: true
        }
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: AlertData.phase === 1

        ColorizedImage {
            x: 380
            y: 68
            source: "qrc:/assets/cluster/card_mid.png"
            color: "#121415"
            opacity: 0.9
        }

        ColorizedImage {
            x: 380
            y: 68
            source: "qrc:/assets/cluster/card_mid_edge.png"
            color: "#8E9396"
            opacity: 0.55
        }

        GlassButton {
            x: 517
            y: 116
            width: 273
            height: 84
            text: AlertData.activeProtocol === 0 ? qsTr("Oil Cooling\nActivated ✓") : qsTr("Start Oil Cooling\nActivation")
            selected: AlertData.protocolIndex === 0
            glowColor: "#C2204A"
        }

        GlassButton {
            x: 517
            y: 237
            width: 273
            height: 84
            text: AlertData.activeProtocol === 1 ? qsTr("Charging\nStopped ✓") : qsTr("Auto Stopping\nCharging")
            selected: AlertData.protocolIndex === 1
            glowColor: Theme.goldTop
        }

        Text {
            x: 0
            y: 324
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("↑ ↓ choose   ·   OK activate")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
