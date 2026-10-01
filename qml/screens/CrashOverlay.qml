import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Crash card, then SOS countdown with "push right to cancel".
//
// Measured against frame_0660. Like the overheat screen, this one is laid out
// about a centre line at 656 rather than the middle of the display.
Item {
    id: crash

    readonly property int axis: 656

    width: Theme.screenWidth
    height: Theme.screenHeight

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: AlertData.phase === 0

        ColorizedImage {
            x: 205
            y: 81
            source: "qrc:/assets/cluster/card_crash.png"
            color: "#161616"
            opacity: 0.9
        }

        ColorizedImage {
            x: 205
            y: 81
            source: "qrc:/assets/cluster/card_crash_edge.png"
            color: "#C9CDCF"
        }

        Ribbon {
            x: crash.axis - width / 2
            y: 99
            fontSize: 21
            text: qsTr("WARNING")
        }

        // The side view, at the box the reference draws it in.
        Image {
            x: 562
            y: 144
            source: "qrc:/assets/cluster/bikeside_crash.png"
        }

        ColorizedImage {
            x: 562
            y: 144
            source: "qrc:/assets/cluster/bikeside_crash_rear.png"
            color: "#D51A2E"
            opacity: 0.9
        }

        Ribbon {
            x: crash.axis - width / 2
            y: 262
            text: qsTr("CRASH DETECTED")
            topColor: "#9A1426"
            bottomColor: "#5C0A14"
            fontSize: 24
            bold: true
            italic: true
        }

        Text {
            x: crash.axis - Theme.screenWidth / 2
            y: 302
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("SOS will be sent to your emergency contacts")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 20
        }

        // The card ends at 367 and the message ink at 326, so the triangle is
        // centred in what is left with 6 px clear either side. At 338 its
        // bottom two rows crossed the card edge and the outline cut through it.
        Icon {
            x: 639
            y: 330
            size: 34
            source: "qrc:/assets/icons/34/triangle.png"
            color: Theme.red
        }
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: AlertData.phase === 1

        ColorizedImage {
            x: 368
            y: 65
            source: "qrc:/assets/cluster/card_sos.png"
            color: "#1C1C1C"
            opacity: 0.95
        }

        ColorizedImage {
            x: 368
            y: 65
            source: "qrc:/assets/cluster/card_sos_edge.png"
            color: "#C9CDCF"
        }

        ColorizedImage {
            x: 480
            y: 56
            width: 320
            height: 160
            source: "qrc:/assets/images/glow_blob_320x160.png"
            color: "#C2204A"
            opacity: 0.35
        }

        Text {
            x: 0
            y: 110
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("ALERT")
            color: "#C9CDCF"
            font.family: Theme.fontFamily
            font.pixelSize: 20
            font.bold: true
        }

        Text {
            x: 0
            y: 146
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            text: AlertData.sosSent ? qsTr("SOS SENT") : qsTr("SENDING SOS")
            color: AlertData.sosSent ? Theme.green : Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
        }

        Row {
            x: (Theme.screenWidth - width) / 2
            y: 210
            visible: !AlertData.sosSent

            Text {
                text: qsTr("DEACTIVATE IN ")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.bold: true
            }

            Text {
                text: "" + AlertData.sosSecondsLeft
                color: Theme.red
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.bold: true
            }

            Text {
                text: qsTr(" SECS")
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 30
                font.bold: true
            }
        }

        Rectangle {
            x: 570
            y: 275
            width: 176
            height: 60
            radius: 30
            visible: !AlertData.sosSent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#414141" }
                GradientStop { position: 1.0; color: "#282828" }
            }

            Rectangle {
                x: 3
                y: 3
                width: 54
                height: 54
                radius: 27
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#55595C" }
                    GradientStop { position: 1.0; color: "#363636" }
                }
            }

            Icon {
                x: 16
                y: 16
                size: 28
                source: "qrc:/assets/icons/28/chevron.png"
                color: Theme.red
            }
        }

        Text {
            x: 0
            y: 342
            width: Theme.screenWidth
            horizontalAlignment: Text.AlignHCenter
            visible: !AlertData.sosSent
            text: qsTr("Push → to cancel if you are safe")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 12
        }
    }
}
