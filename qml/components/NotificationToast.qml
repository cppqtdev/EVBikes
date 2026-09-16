import QtQuick
import ClusterCore
import ClusterBackend

// Shows the latest message for a few seconds. Text is only shown when stopped.
Item {
    id: toast

    property bool shown: false

    width: 420
    height: 56
    opacity: shown ? 1.0 : 0.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }

    Connections {
        target: PhoneData
        function onNotificationSeqChanged() {
            toast.shown = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 4000
        onTriggered: toast.shown = false
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusL
        color: Theme.surfaceRaised
    }

    Icon {
        id: msgIcon
        x: Theme.spaceL
        anchors.verticalCenter: parent.verticalCenter
        size: 24
        source: "qrc:/assets/icons/24/bell.png"
        color: Theme.accent
    }

    Text {
        anchors.left: msgIcon.right
        anchors.leftMargin: Theme.spaceM
        anchors.right: parent.right
        anchors.rightMargin: Theme.spaceM
        anchors.verticalCenter: parent.verticalCenter
        text: VehicleData.speedKmh > 0 ? PhoneData.notificationSender + qsTr(" sent a message")
                                        : PhoneData.notificationSender + ": " + PhoneData.notificationText
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: Theme.fontBody
        elide: Text.ElideRight
    }
}
