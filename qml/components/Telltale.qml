import QtQuick
import ClusterCore

Item {
    id: telltale

    property alias source: icon.source
    property bool active: false
    property bool blinking: false
    property int size: 26
    property color activeColor: Theme.telltaleGreen
    property color inactiveColor: Theme.telltaleOff
    property real blinkPhase: 1.0

    readonly property bool flashing: telltale.active && telltale.blinking

    width: size
    height: size

    // Indicator cadence: about 1.2 Hz, the rate a real flasher relay runs at.
    SequentialAnimation {
        running: telltale.visible && telltale.flashing
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
        fillMode: Image.PreserveAspectFit
        color: telltale.active ? telltale.activeColor : telltale.inactiveColor
        opacity: telltale.flashing ? telltale.blinkPhase : 1.0

        Behavior on color {
            ColorAnimation { duration: Theme.animFast }
        }
    }
}
