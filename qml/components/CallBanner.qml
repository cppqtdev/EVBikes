import QtQuick
import ClusterCore
import ClusterBackend

Item {
    id: banner

    property bool shown: PhoneData.callStatus !== PhoneData.Idle

    width: 420
    height: 64
    y: shown ? 76 : -height - 20
    visible: y > -height - 20

    Behavior on y {
        NumberAnimation { duration: Theme.animNormal; easing.type: Easing.OutCubic }
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusL
        color: Theme.surfaceRaised
    }

    Icon {
        id: phoneIcon
        x: Theme.spaceL
        anchors.verticalCenter: parent.verticalCenter
        size: 30
        source: "qrc:/assets/icons/30/phone.png"
        color: Theme.green
    }

    Column {
        anchors.left: phoneIcon.right
        anchors.leftMargin: Theme.spaceM
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: PhoneData.callerName
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontHeading
            font.bold: true
        }

        CaptionText {
            text: PhoneData.callStatus === PhoneData.Ringing ? qsTr("Incoming call  ·  OK answer  ·  BACK reject")
                                                              : qsTr("On call")
            font.bold: false
        }
    }
}
