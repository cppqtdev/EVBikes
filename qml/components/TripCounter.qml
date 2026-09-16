import QtQuick
import ClusterCore
import ClusterBackend

// Four-digit trip counter with a faint reflection.
Item {
    id: trip

    property int value: Math.floor(VehicleData.tripKmX10 / 10)

    width: 180
    height: 90

    Text {
        anchors.right: parent.right
        anchors.rightMargin: 30
        y: 0
        text: qsTr("TRIP")
        color: Theme.labelTeal
        font.family: Theme.fontFamily
        font.pixelSize: 19
        font.bold: true
        font.italic: true
    }

    Repeater {
        model: 4

        Item {
            x: index * 38.5
            y: 28
            width: 28
            height: 52

            Rectangle {
                width: 28
                height: 25
                radius: 3
                color: Theme.surfaceSunken
            }

            Rectangle {
                y: 24
                width: 28
                height: 1
                color: "#252525"
            }

            Text {
                width: 28
                y: 1
                horizontalAlignment: Text.AlignHCenter
                text: Format.digitAt(trip.value, 3 - index)
                color: Theme.textPrimary
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.italic: true
            }

            Text {
                width: 28
                y: 26
                horizontalAlignment: Text.AlignHCenter
                text: Format.digitAt(trip.value, 3 - index)
                color: Theme.textPrimary
                opacity: 0.12
                font.family: Theme.fontFamily
                font.pixelSize: 18
                font.italic: true
            }
        }
    }
}
