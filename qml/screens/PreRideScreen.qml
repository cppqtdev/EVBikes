import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend
import ClusterComponents

// Pre-ride check: side stand warning and connectivity status.
Item {
    id: check

    property bool standDown: VehicleData.sideStandDown
    property bool ready: !standDown

    width: Theme.screenWidth
    height: Theme.screenHeight

    Timer {
        interval: 2500
        running: check.visible && check.ready
        onTriggered: Router.finishPreRide()
    }

    // Measured on frame_0260: the side view, 250 by 120, at x 518.
    Image {
        x: 518
        y: 103
        source: "qrc:/assets/cluster/bikeside_preride.png"
    }

    Item {
        width: Theme.screenWidth
        height: Theme.screenHeight
        visible: check.standDown

        ColorizedImage {
            x: 578
            y: 165
            width: 80
            height: 80
            source: "qrc:/assets/images/glow_blob_80x80.png"
            color: Theme.red
            opacity: 0.8
        }

        Rectangle {
            x: 610
            y: 197
            width: 16
            height: 16
            radius: 8
            color: "#E3263A"
        }

        Rectangle {
            x: 618
            y: 204
            width: 168
            height: 2
            color: "#C0283A"
            transform: Rotation {
                origin.x: 0
                origin.y: 1
                angle: -15.5
            }
        }

        ColorizedImage {
            x: 785
            y: 110
            source: "qrc:/assets/cluster/callout.png"
            color: "#2A1A1C"
        }

        Icon {
            x: 810
            y: 115
            size: 24
            source: "qrc:/assets/icons/24/triangle.png"
            color: "#E05A68"
        }

        Text {
            x: 838
            y: 112
            text: qsTr("Warning")
            color: "#E05A68"
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.italic: true
        }

        ColorizedImage {
            x: 780
            y: 143
            source: "qrc:/assets/cluster/callout.png"
            color: "#A81C2C"
        }

        Text {
            x: 780
            y: 146
            width: 240
            horizontalAlignment: Text.AlignHCenter
            text: qsTr("Side stand alert")
            color: Theme.white
            font.family: Theme.fontFamily
            font.pixelSize: 22
            font.italic: true
        }
    }

    GlowBand {
        x: 490
        y: 262
        width: 320
        height: 26
        bandColor: check.ready ? "#1F6F58" : "#6E1420"
    }

    Text {
        x: 10
        y: 266
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: check.ready ? qsTr("CONNECTED") : qsTr("CONNECTIVITY")
        color: "#ECEFF0"
        font.family: Theme.fontFamily
        font.pixelSize: 16
        font.bold: true
        font.italic: true
    }

    Repeater {
        model: 3

        Item {
            x: 571 + index * 60
            y: 308
            width: 46
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: 6
                color: "#141414"
            }

            Icon {
                anchors.centerIn: parent
                size: 30
                source: index === 0 ? "qrc:/assets/icons/34/bluetooth.png"
                      : (index === 1 ? "qrc:/assets/icons/34/helmet.png" : "qrc:/assets/icons/34/watch.png")
                color: index === 0 ? (PhoneData.connected ? Theme.teal : "#8C9194")
                     : (index === 1 ? (check.ready ? "#7FE39A" : "#9FA4A7") : "#9FA4A7")
            }
        }
    }

    Text {
        x: 0
        y: 372
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: check.standDown
        text: qsTr("Lift the side stand to continue")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }
}
