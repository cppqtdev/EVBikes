import QtQuick
import ClusterCore
import ClusterBackend

// The call, full width. A rider reads this at a glance and answers with one
// button, so it replaces the small banner the call used to get.
Item {
    id: call

    readonly property bool ringing: PhoneData.callStatus === PhoneData.Ringing
    readonly property bool active: PhoneData.callStatus === PhoneData.Active
    readonly property string who: PhoneData.callerName !== "" ? PhoneData.callerName : qsTr("Unknown")

    property int seconds: 0
    property real pulse: 0.0

    width: Theme.screenWidth
    height: Theme.screenHeight
    opacity: PhoneData.callStatus === PhoneData.Idle ? 0.0 : 1.0
    visible: opacity > 0

    Behavior on opacity {
        NumberAnimation { duration: Theme.animNormal }
    }

    onActiveChanged: {
        if (call.active)
            call.seconds = 0
    }

    Timer {
        interval: 1000
        repeat: true
        running: call.active
        onTriggered: call.seconds = call.seconds + 1
    }

    SequentialAnimation {
        running: call.ringing
        loops: Animation.Infinite

        NumberAnimation { target: call; property: "pulse"; to: 1.0; duration: 750; easing.type: Easing.OutCubic }
        NumberAnimation { target: call; property: "pulse"; to: 0.0; duration: 750; easing.type: Easing.InCubic }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.shell
        opacity: 0.93
    }

    // The ring the caller makes: a halo that swells once a second.
    Rectangle {
        x: 640 - width / 2
        y: 158 - height / 2
        width: 118 + 70 * call.pulse
        height: width
        radius: width / 2
        color: Theme.green
        opacity: call.ringing ? 0.20 * (1.0 - call.pulse) : 0.0
    }

    Rectangle {
        x: 640 - 46
        y: 158 - 46
        width: 92
        height: 92
        radius: 46
        color: "#2F8A6C"

        Text {
            anchors.centerIn: parent
            text: call.who.charAt(0)
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 40
            font.bold: true
        }
    }

    Text {
        x: 0
        y: 224
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: call.who
        color: Theme.textPrimary
        font.family: Theme.fontFamily
        font.pixelSize: 30
        font.bold: true
    }

    Text {
        x: 0
        y: 262
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: call.ringing
        text: qsTr("Incoming call")
        color: Theme.textSecondary
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }

    Text {
        x: 0
        y: 262
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: call.active
        text: Format.durationText(call.seconds)
        color: Theme.labelTeal
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    // Reject sits left and answer right, the way the handlebar buttons do.
    Item {
        x: 640 - 200
        y: 300
        width: 180
        height: 46
        visible: call.ringing || call.active

        Rectangle {
            anchors.fill: parent
            radius: 23
            color: "#3A1618"
        }

        Text {
            anchors.centerIn: parent
            text: call.active ? qsTr("BACK  end") : qsTr("BACK  reject")
            color: Theme.telltaleRed
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
        }
    }

    Item {
        x: 640 + 20
        y: 300
        width: 180
        height: 46
        visible: call.ringing

        Rectangle {
            anchors.fill: parent
            radius: 23
            color: "#143A2A"
        }

        Text {
            anchors.centerIn: parent
            text: qsTr("OK  answer")
            color: Theme.green
            font.family: Theme.fontFamily
            font.pixelSize: 16
            font.bold: true
        }
    }
}
