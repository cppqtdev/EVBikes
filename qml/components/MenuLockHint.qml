import QtQuick
import ClusterCore
import ClusterBackend

// Shown when OK is pressed while the bike is moving: the menu only opens when stopped.
Item {
    id: hint

    property bool shown: false
    property int requestSeq: Router.menuBlockedSeq

    width: 340
    height: 34
    opacity: shown ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }

    onRequestSeqChanged: {
        hint.shown = true
        hideTimer.restart()
    }

    Timer {
        id: hideTimer
        interval: 2000
        onTriggered: hint.shown = false
    }

    Rectangle {
        anchors.fill: parent
        radius: 17
        color: "#4A5053"
    }

    Rectangle {
        x: 1
        y: 1
        width: parent.width - 2
        height: parent.height - 2
        radius: 16
        color: "#1E2224"
    }

    Text {
        width: parent.width
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: Simulator.running ? qsTr("Stop the bike to open the menu (P = park)") : qsTr("Stop the bike to open the menu")
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
