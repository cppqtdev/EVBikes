import QtQuick
import ClusterCore

Item {
    id: telltale

    property alias source: icon.source
    property bool on: false
    property bool blinking: false
    property int size: 26
    property color onColor: Theme.telltaleGreen
    property color offColor: Theme.telltaleOff
    property real blinkPhase: 1.0

    readonly property bool flashing: telltale.on && telltale.blinking

    width: size
    height: size

    // Indicator cadence: about 1.2 Hz, the rate a real flasher relay runs at.
    SequentialAnimation {
        running: telltale.flashing
        loops: Animation.Infinite

        NumberAnimation { target: telltale; property: "blinkPhase"; to: 1.0; duration: 80 }
        PauseAnimation { duration: 330 }
        NumberAnimation { target: telltale; property: "blinkPhase"; to: 0.0; duration: 80 }
        PauseAnimation { duration: 330 }
    }

    Icon {
        id: icon
        anchors.centerIn: parent
        size: telltale.size
        color: telltale.on ? telltale.onColor : telltale.offColor
        opacity: telltale.flashing ? telltale.blinkPhase : 1.0

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }
}
