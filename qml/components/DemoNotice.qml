import QtQuick
import ClusterCore
import ClusterBackend

// Marks a page whose content has nothing behind it yet. In demo mode it is a
// small badge over the sample content; with demo mode off the page says plainly
// that the feature is not connected, so a shipped cluster never shows a
// document, a payment or a rider that was made up.
Item {
    id: notice

    property string subject: qsTr("This")
    readonly property bool demo: SystemData.demoMode

    width: Theme.screenWidth
    height: 300

    Rectangle {
        x: 900
        y: 96
        width: 58
        height: 18
        radius: 3
        color: "#242424"
        visible: notice.demo

        Text {
            x: 0
            y: 0
            width: 58
            height: 18
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            text: qsTr("DEMO")
            color: Theme.textMuted
            font.family: Theme.fontFamily
            font.pixelSize: 10
            font.bold: true
        }
    }

    Text {
        x: 0
        y: 170
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        visible: !notice.demo
        text: notice.subject + qsTr(" is not connected yet")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 14
    }
}
