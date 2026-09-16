import QtQuick
import QtQuickUltralite.Extras
import ClusterCore
import ClusterBackend

PageBase {
    pageId: Router.menuProfile

    Repeater {
        model: 3

        Item {
            property bool selected: SystemData.profileIndex === index

            x: (index === 0 ? 500 : (index === 1 ? 651 : 805)) - 60
            y: 90
            width: 120
            height: 150

            ColorizedImage {
                x: 7
                y: 10
                visible: parent.selected
                source: "qrc:/assets/cluster/avatar_106.png"
                color: "#DADDDE"
            }

            ColorizedImage {
                x: 14
                y: 17
                visible: !parent.selected
                source: "qrc:/assets/cluster/avatar_92.png"
                color: "#8C9194"
            }

            Text {
                y: 122
                width: 120
                horizontalAlignment: Text.AlignHCenter
                text: Format.profileName(index)
                color: parent.selected ? Theme.textPrimary : "#7B8285"
                font.family: Theme.fontFamily
                font.pixelSize: 16
            }
        }
    }

    Text {
        x: 0
        y: 262
        width: Theme.screenWidth
        horizontalAlignment: Text.AlignHCenter
        text: qsTr("↑ ↓ switch rider")
        color: Theme.textMuted
        font.family: Theme.fontFamily
        font.pixelSize: 13
    }
}
