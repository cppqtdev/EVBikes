import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Overheating: "Slow Down!" first, then the protocol choices.
Item {
    id: heat

    width: Theme.screenWidth
    height: Theme.screenHeight

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: AlertData.phase === 0

        GlowBand {
            x: 500
            y: 72
            width: 310
            height: 28
            bandColor: "#9A1426"
        }

        Text {
            x: 0
            y: 72
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: AlertData.kind === AlertData.BatteryOverheat ? qsTr("Battery Over Heating!") : qsTr("Over Heating!")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 22
        }

        Image {
            x: 560
            y: 98
            source: "qrc:/assets/cluster/bike_180.png"
        }

        Icon {
            x: 604
            y: 112
            size: 96
            source: "qrc:/assets/icons/96/triangle.png"
            color: "#D51A2E"
            opacity: 0.9
        }

        Ribbon {
            x: 485
            y: 243
            text: qsTr("PROTOCOLS")
        }

        Text {
            x: 0
            y: 292
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Slow Down!")
            color: "#E0142A"
            font.family: Theme.fontFamily
            font.pixelSize: 46
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
            y: 334
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("↑ ↓ choose   ·   OK activate")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
